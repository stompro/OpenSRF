package OpenSRF::Utils::Cache;
use strict; use warnings;
use base qw/OpenSRF/;
use Cache::Memcached;
use OpenSRF::Utils::Logger qw/:level/;
use OpenSRF::Utils::Config;
use OpenSRF::Utils::SettingsClient;
use OpenSRF::EX qw(:try);
use OpenSRF::Utils::JSON;

my $log = 'OpenSRF::Utils::Logger';

=head1 NAME

OpenSRF::Utils::Cache

=head1 SYNOPSIS

This class just subclasses Cache::Memcached.
see Cache::Memcached for more options.

The value passed to the call to current is the cache type
you wish to access.  The below example sets/gets data
from the 'user' cache.

my $cache = OpenSRF::Utils::Cache->current("user");
$cache->set( "key1", "value1" [, $expire_secs ] );
my $val = $cache->get( "key1" );


=cut

sub DESTROY {}

my %caches;

# ------------------------------------------------------
# Persist methods and method names
# ------------------------------------------------------
my $persist_add_slot; 
my $persist_push_stack;
my $persist_peek_stack;
my $persist_destroy_slot;
my $persist_slot_get_expire;
my $persist_slot_find;

my $max_persist_time;
my $persist_add_slot_name	 = "opensrf.persist.slot.create_expirable";
my $persist_push_stack_name	 = "opensrf.persist.stack.push";
my $persist_peek_stack_name	 = "opensrf.persist.stack.peek";
my $persist_destroy_slot_name	 = "opensrf.persist.slot.destroy";
my $persist_slot_get_expire_name = "opensrf.persist.slot.get_expire";
my $persist_slot_find_name	 = "opensrf.persist.slot.find";;

# ------------------------------------------------------

=head1 METHODS

=head2 current

Return a named cache if it exists

=cut

sub current {
	my ( $class, $c_type )  = @_;
	return undef unless $c_type;
	return $caches{$c_type} if exists $caches{$c_type};
	return $caches{$c_type} = $class->new( $c_type );
}


=head2 new

Create a new named memcache object.

=cut

sub new {

	my( $class, $cache_type, $persist ) = @_;
	$cache_type ||= 'global';
	$class = ref( $class ) || $class;

	return $caches{$cache_type} if (defined $caches{$cache_type});

	my $conf = OpenSRF::Utils::SettingsClient->new;
	my $servers = $conf->config_value( cache => $cache_type => servers => 'server' );
	$max_persist_time = $conf->config_value( cache => $cache_type => 'max_cache_time' );

	$servers = [ $servers ] if(!ref($servers));

	my $self = {};
	$self->{persist} = $persist || 0;
	$self->{memcache} = Cache::Memcached->new( { servers => $servers } ); 
	if(!$self->{memcache}) {
		throw OpenSRF::EX::PANIC ("Unable to create a new memcache object for $cache_type");
	}

	bless($self, $class);
	$caches{$cache_type} = $self;
	return $self;
}


=head2 put_cache

=cut

sub put_cache {
	my($self, $key, $value, $expiretime ) = @_;

	return undef unless( defined $key and defined $value );

	$key = _clean_cache_key($key);

	return undef if( $key eq '' ); # no zero-length keys

	$value = OpenSRF::Utils::JSON->perl2JSON($value);

	if($self->{persist}){ _load_methods(); }

	$expiretime ||= $max_persist_time;

	unless( $self->{memcache}->set( $key, $value, $expiretime ) ) {
		$log->error("Unable to store $key => [".length($value)." bytes]  in memcached server" );
		return undef;
	}

	$log->debug("Stored $key => $value in memcached server", INTERNAL);

	if($self->{"persist"}) {

		my ($slot) = $persist_add_slot->run("_CACHEVAL_$key", $expiretime . "s");

		if(!$slot) {
			# slot may already exist
			($slot) = $persist_slot_find->run("_CACHEVAL_$key");
			if(!defined($slot)) {
				throw OpenSRF::EX::ERROR ("Unable to create cache slot $key in persist server" );
			} else {
				#XXX destroy the slot and rebuild it to prevent DOS
			}
		}

		($slot) = $persist_push_stack->run("_CACHEVAL_$key", $value);

		if(!$slot) {
			throw OpenSRF::EX::ERROR ("Unable to push data onto stack in persist slot _CACHEVAL_$key" );
		}
	}

	return $key;
}


=head2 delete_cache

=cut

sub delete_cache {
	my( $self, $key ) = @_;
	return undef unless defined $key;
	$key = _clean_cache_key($key);
	return undef if $key eq ''; # no zero-length keys
	if($self->{persist}){ _load_methods(); }
	$self->{memcache}->delete($key);
	if( $self->{persist} ) {
		$persist_destroy_slot->run("_CACHEVAL_$key");
	}
	return $key; 
}


=head2 get_cache

=cut

sub get_cache {
	my($self, $key ) = @_;

	return undef unless defined $key;

	$key = _clean_cache_key($key);

	return undef if $key eq ''; # no zero-length keys

	my $val = $self->{memcache}->get( $key );
	return OpenSRF::Utils::JSON->JSON2perl($val) if defined($val);

	if($self->{persist}){ _load_methods(); }

	# if not in memcache but we are persisting, the put it into memcache
	if( $self->{"persist"} ) {
		$val = $persist_peek_stack->( "_CACHEVAL_$key" );
		if(defined($val)) {
			my ($expire) = $persist_slot_get_expire->run("_CACHEVAL_$key");
			if($expire)	{
				$self->{memcache}->set( $key, $val, $expire);
			} else {
				$self->{memcache}->set( $key, $val, $max_persist_time);
			}
			return OpenSRF::Utils::JSON->JSON2perl($val);
		}
	}
	return undef;
}


=head2 _load_methods

=cut

sub _load_methods {

	if(!$persist_add_slot) {
		$persist_add_slot = 
			OpenSRF::Application->method_lookup($persist_add_slot_name);
		if(!ref($persist_add_slot)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_add_slot_name");
		}
	}

	if(!$persist_push_stack) {
		$persist_push_stack = 
			OpenSRF::Application->method_lookup($persist_push_stack_name);
		if(!ref($persist_push_stack)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_push_stack_name");
		}
	}

	if(!$persist_peek_stack) {
		$persist_peek_stack = 
			OpenSRF::Application->method_lookup($persist_peek_stack_name);
		if(!ref($persist_peek_stack)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_peek_stack_name");
		}
	}

	if(!$persist_destroy_slot) {
		$persist_destroy_slot = 
			OpenSRF::Application->method_lookup($persist_destroy_slot_name);
		if(!ref($persist_destroy_slot)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_destroy_slot_name");
		}
	}
	if(!$persist_slot_get_expire) {
		$persist_slot_get_expire = 
			OpenSRF::Application->method_lookup($persist_slot_get_expire_name);
		if(!ref($persist_slot_get_expire)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_slot_get_expire_name");
		}
	}
	if(!$persist_slot_find) {
		$persist_slot_find = 
			OpenSRF::Application->method_lookup($persist_slot_find_name);
		if(!ref($persist_slot_find)) {
			throw OpenSRF::EX::PANIC ("Unable to retrieve method $persist_slot_find_name");
		}
	}
}


=head2 _clean_cache_key

Try to make the requested cache key conform to memcached's requirements. Per
https://github.com/memcached/memcached/blob/master/doc/protocol.txt:

"""
Data stored by memcached is identified with the help of a key. A key
is a text string which should uniquely identify the data for clients
that are interested in storing and retrieving it.  Currently the
length limit of a key is set at 250 characters (of course, normally
clients wouldn't need to use such long keys); the key must not include
control characters or whitespace.
"""

=cut

sub _clean_cache_key {
    my $key = shift;

    $key =~ s{(\p{Cntrl}|\s)}{}g;

    return $key;
}

1;

