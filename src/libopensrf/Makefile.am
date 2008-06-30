# Copyright (C) 2008 Equinox Software, Inc.
# Kevin Beswick <kevinbeswick00@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


AM_CFLAGS = $(DEF_CFLAGS) -DASSUME_STATELESS  -DOSRF_STRICT_PARAMS -rdynamic -fno-strict-aliasing -L./.libs/ -DOSRF_JSON_ENABLE_XML_UTILS
AM_LDFLAGS = $(DEF_LDFLAGS)
LDADD = -lxml2 -ldl -lmemcache -lopensrf -lobjson

export OSRF_INC = @abs_top_builddir@/include/opensrf/

TARGS = 		osrf_message.c \
			osrf_app_session.c \
			osrf_stack.c \
			osrf_system.c \
			osrf_settings.c \
			osrf_prefork.c \
			osrfConfig.c \
			osrf_application.c \
			osrf_cache.c \
			osrf_transgroup.c \
			osrf_list.c \
			osrf_hash.c \
			xml_utils.c \
			transport_message.c\
			transport_session.c\
			transport_client.c\
			md5.c\
			log.c\
			utils.c\
			socket_bundle.c\
			sha.c\
			string_array.c

TARGS_HEADS = 	 $(OSRF_INC)/transport_message.h \
		 $(OSRF_INC)/transport_session.h \
		 $(OSRF_INC)/transport_client.h \
		 $(OSRF_INC)/osrf_message.h \
		 $(OSRF_INC)/osrf_app_session.h \
		 $(OSRF_INC)/osrf_stack.h \
		 $(OSRF_INC)/osrf_system.h \
		 $(OSRF_INC)/osrf_settings.h \
		 $(OSRF_INC)/osrf_prefork.h \
		 $(OSRF_INC)/osrfConfig.h \
		 $(OSRF_INC)/osrf_application.h \
		 $(OSRF_INC)/osrf_cache.h \
		 $(OSRF_INC)/osrf_list.h \
		 $(OSRF_INC)/osrf_hash.h \
		 $(OSRF_INC)/md5.h \
		 $(OSRF_INC)/log.h \
		 $(OSRF_INC)/utils.h \
		 $(OSRF_INC)/socket_bundle.h \
		 $(OSRF_INC)/sha.h \
		 $(OSRF_INC)/string_array.h \
		 $(OSRF_INC)/osrf_json_utils.h \
		 $(OSRF_INC)/osrf_json_xml.h 

JSON_TARGS = 			osrf_json_object.c\
				osrf_json_parser.c \
				osrf_json_tools.c \
				osrf_legacy_json.c \
				osrf_json_xml.c

# use these when building the standalone JSON module
JSON_DEP = 		osrf_list.c\
			osrf_hash.c\
			utils.c\
			log.c\
			md5.c\
			string_array.c

JSON_TARGS_HEADS = 		$(OSRF_INC)/osrf_json_object.h\
				$(OSRF_INC)/osrf_json_parser.h \
				$(OSRF_INC)/osrf_json_tools.h \
				$(OSRF_INC)/osrf_legacy_json.h \
				$(OSRF_INC)/osrf_json_xml.h

JSON_DEP_HEADS = 	$(OSRF_INC)/osrf_list.h\
			$(OSRF_INC)/osrf_hash.h\
			$(OSRF_INC)/utils.h\
			$(OSRF_INC)/log.h\
			$(OSRF_INC)/md5.h\
			$(OSRF_INC)/string_array.h


noinst_PROGRAMS = osrf_json_test

bin_PROGRAMS = opensrf
opensrf_SOURCES = opensrf.c
opensrf_DEPENDENCIES = libopensrf.la

osrf_json_test_SOURCES = osrf_json_test.c $(JSON_TARGS) $(JSON_DEP) $(JSON_TARGS_HEADS) $(JSON_DEP_HEADS)

noinst_LTLIBRARIES = libosrf_json.la
lib_LTLIBRARIES = libobjson.la libopensrf.la

if BUILDJSON
libobjson_la_SOURCES = $(JSON_TARGS) $(JSON_DEP) $(JSON_TARGS_HEADS) $(JSON_DEP_HEADS)
libobjson_la_CFLAGS = $(AM_CFLAGS)
endif

libosrf_json_la_SOURCES = $(JSON_TARGS) $(JSON_DEP) $(JSON_TARGS_HEADS) $(JSON_DEP_HEADS)
libosrf_json_la_CFLAGS = $(AM_CFLAGS)

if BUILDJSON
libosrf_json_la_DEPENDENCIES = libobjson.la
endif

libopensrf_la_CFLAGS = $(AM_CFLAGS)
libopensrf_la_DEPENDENCIES = libosrf_json.la

if BUILDJSON
libopensrf_la_SOURCES = $(TARGS) $(TARGS_HEADS)
else
libopensrf_la_SOURCES = $(TARGS) $(TARGS_HEADS) $(JSON_TARGS) $(JSON_TARGS_HEADS)
endif

install-exec-hook:
	## Remove extra lib files created by libtool.
	rm $(LIBDIR)/libobjson.a
	rm $(LIBDIR)/libobjson.la
	rm $(LIBDIR)/libobjson.so
	mv $(LIBDIR)/libobjson.so.*.*.* $(LIBDIR)/libobjson.so
	rm $(LIBDIR)/libobjson.so.*

	rm $(LIBDIR)/libopensrf.a
	rm $(LIBDIR)/libopensrf.la
	rm $(LIBDIR)/libopensrf.so
	mv $(LIBDIR)/libopensrf.so.*.*.* $(LIBDIR)/libopensrf.so
	rm $(LIBDIR)/libopensrf.so.*