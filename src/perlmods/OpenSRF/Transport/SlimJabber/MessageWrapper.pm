package OpenSRF::Transport::SlimJabber::MessageWrapper;
use XML::LibXML;
use OpenSRF::EX qw/:try/;
use OpenSRF::Utils::Logger qw/$logger/;

sub new {
	my $class = shift;
	$class = ref($class) || $class;

	my $xml = shift;

	my ($doc, $msg);
	if ($xml) {
		my $err;

		try {
			$doc = XML::LibXML->new->parse_string($xml);
		} catch Error with {
			$err = shift; 
			warn "MessageWrapper received bad XML : error = $err\nXML = $xml\n";
			$logger->error("MessageWrapper received bad XML : error = $err : XML = $xml");
		};
		throw $err if $err;

		$msg = $doc->documentElement;
	} else {
		$doc = XML::LibXML::Document->createDocument;
		$msg = $doc->createElement( 'message' );
		$doc->setDocumentElement( $msg );
	}

	
	my $self = { msg_node => $msg };

	return bless $self => $class;
}

sub toString {
	my $self = shift;
	if( $self->{msg_node} ) {
		return $self->{msg_node}->toString(@_);
	}
	return "";
}

sub get_body {
	my $self = shift;
	my ($t_body) = grep {$_->nodeName eq 'body'} $self->{msg_node}->childNodes;
	if( $t_body ) {
		my $body = $t_body->textContent;
		return $body;
	}
	return "";
}

sub get_sess_id {
	my $self = shift;
	my ($t_node) = grep {$_->nodeName eq 'thread'} $self->{msg_node}->childNodes;
	if( $t_node ) {
		return $t_node->textContent;
	}
	return "";
}

sub get_msg_type {
	my $self = shift;
	$self->{msg_node}->getAttribute( 'type' );
}

sub get_remote_id {
	my $self = shift;

	#
	my $rid = $self->{msg_node}->getAttribute( 'router_from' );
	return $rid if $rid;

	return $self->{msg_node}->getAttribute( 'from' );
}

sub setType {
	my $self = shift;
	$self->{msg_node}->setAttribute( type => shift );
}

sub setTo {
	my $self = shift;
	$self->{msg_node}->setAttribute( to => shift );
}

sub setThread {
	my $self = shift;
	$self->{msg_node}->appendTextChild( thread => shift );
}

sub setBody {
	my $self = shift;
	my $body = shift;
	$self->{msg_node}->appendTextChild( body => $body );
}

sub set_router_command {
	my( $self, $router_command ) = @_;
	if( $router_command ) {
		$self->{msg_node}->setAttribute( router_command => $router_command );
	}
}
sub set_router_class {
	my( $self, $router_class ) = @_;
	if( $router_class ) {
		$self->{msg_node}->setAttribute( router_class => $router_class );
	}
}

sub set_osrf_xid {
   my( $self, $xid ) = @_;
   $self->{msg_node}->setAttribute( osrf_xid => $xid );
}


sub get_osrf_xid {
   my $self = shift;
   $self->{msg_node}->getAttribute('osrf_xid');
}

sub set_locale {
   my( $self, $xid ) = @_;
   $self->{msg_node}->setAttribute( locale => $xid );
}


sub get_locale {
   my $self = shift;
   $self->{msg_node}->getAttribute('locale');
}


1;
