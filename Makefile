PROGRAM=tasksel
DOMAIN=debian-tasks
TASKDESC=$(DOMAIN).desc
TASKDIR=/usr/share/tasksel
DESCDIR=tasks
DESCPO=$(DESCDIR)/po
CC=gcc
CFLAGS=-g -Wall  #-Os
DEBUG=1
ifeq (0,$(DEBUG))
DEFS=-DVERSION=\"$(VERSION)\" -DPACKAGE=\"$(PROGRAM)\" -DLOCALEDIR=\"/usr/share/locale\" \
     -DTASKDIR=\"$(TASKDIR)\"
else
DEFS=-DVERSION=\"$(VERSION)\" -DPACKAGE=\"$(PROGRAM)\" -DLOCALEDIR=\"/usr/share/locale\" \
     -DTASKDIR=\".\" -DDEBUG
endif
VERSION=$(shell expr "`dpkg-parsechangelog 2>/dev/null |grep Version:`" : '.*Version: \(.*\)' | cut -d - -f 1)
LIBS=-lslang -ltextwrap #-lccmalloc -ldl
OBJS=tasksel.o slangui.o data.o util.o strutl.o
LANGS=cs da de es fr hu it ja no nn pl pt_BR ru sv zh_TW
LANGS_DESC=de ja
LOCALEDIR=$(DESTDIR)/usr/share/locale
COMPILE = $(CC) $(CFLAGS) $(DEFS) -c
LINK = $(CC) $(CFLAGS) $(DEFS) -o

all: $(PROGRAM) $(TASKDESC) $(DESCPO)/build_stamp

$(TASKDESC): makedesc.pl $(DESCDIR)/[a-z]??*
	perl doincludes.pl $(DESCDIR)
	perl makedesc.pl $(DESCDIR) $(TASKDESC)

%.o: %.c
	$(COMPILE) $<

po/build_stamp:
	$(MAKE) -C po LANGS="$(LANGS)"

updatepo:
	$(MAKE) -C po update LANGS="$(LANGS)"

$(DESCPO)/build_stamp:
	$(MAKE) -C $(DESCPO) LANGS="$(LANGS_DESC)"

$(PROGRAM): $(OBJS) po/build_stamp
	$(LINK) $(PROGRAM) $(OBJS) $(LIBS)

install:
	install -m 755 tasksel $(DESTDIR)/usr/bin
	install -m 0644 $(TASKDESC) $(DESTDIR)$(TASKDIR)
	pod2man --center "Debian specific manpage" --release $(VERSION) tasksel.pod | gzip -9c > $(DESTDIR)/usr/share/man/man8/tasksel.8.gz
	for lang in $(LANGS); do \
	  [ ! -d $(LOCALEDIR)/$$lang/LC_MESSAGES/ ] && mkdir -p $(LOCALEDIR)/$$lang/LC_MESSAGES/; \
	  install -m 644 po/$$lang.mo $(LOCALEDIR)/$$lang/LC_MESSAGES/$(PROGRAM).mo; \
	done
	for lang in $(LANGS_DESC); do \
	  [ ! -d $(LOCALEDIR)/$$lang/LC_MESSAGES/ ] && mkdir -p $(LOCALEDIR)/$$lang/LC_MESSAGES/; \
	  install -m 644 tasks/po/$$lang.mo $(LOCALEDIR)/$$lang/LC_MESSAGES/$(DOMAIN).mo; \
	done

test:
	$(MAKE) -C scratch

clean:
	rm -f $(PROGRAM) $(TASKDESC) *.o *~
	$(MAKE) -C po clean
	$(MAKE) -C $(DESCPO) clean

# This taget is run on auric to generate the overrides files.
# It is run from a cron job, so should only generate output if there are
# problems.
override:
	@cvs up tasks 2>&1 | grep -v ^U | grep -v ".cvspass" || true
	@perl makeoverride.pl $(DESCDIR) > temp-override
	@cp temp-override /org/ftp.debian.org/scripts/external-overrides/task
	@rm -f temp-override
