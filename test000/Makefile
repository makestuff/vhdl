# Makefile commands taken from test.cmd_log
# rm -rf $(find . -maxdepth 1 -type d | grep / | perl -ane 'chomp; print "$_ ";'; find . -maxdepth 1 -type f | awk -F. '{print $NF}' | sort | uniq | grep -Ev '(batch|xise|vhd|ucf|Makefile)' | perl -ane 'chomp; print "*.$_ ";')
#
all: test.xsvf

test.ngc: test.vhd test.ucf
	mkdir -p xst/projnav.tmp
	xst -ise test000.ise -intstyle ise -ifn test.xst -ofn test.syr

test.ngd: test.ngc
	ngdbuild -ise test000.ise -intstyle ise -dd _ngo -i -p xc9572-PC84-15 test.ngc test.ngd

test.vm6: test.ngd
	cpldfit -ise test000.ise -intstyle ise -p xc9572-15-PC84 -ofmt vhdl -optimize speed -htmlrpt -loc on -slew fast -init low -inputs 36 -pterms 25 -power std -localfbk -pinfbk test.ngd
	XSLTProcess -ise test000.ise test_build.xml

test.nga: test.vm6
	tsim -ise test000.ise -intstyle ise test test.nga
	touch tagui.out
	taengine -ise test000.ise -intstyle ise -f test -w --format html1 -l test_html/tim/timing_report.htm 

test.jed: test.nga
	hprep6 -ise test000.ise -s IEEE1149 -n test -i test 

test.xsvf: test.jed
	impact -batch impact.batch

flash: test.xsvf
	..\..\apps\nanduinoJtag\host\Debug\nj --load=test.xsvf

clean: FORCE
	rm -rf ./_xmsgs ./test000_xdb ./_ngo ./xst ./test_html *.bld *.cmd_log *.csv *.err *.gise *.gyd *.html *.ise *.jed *.log *.lso *.mfd *.nga *.ngc *.ngd *.ngr *.pad *.pnx *.prj *.rpt *.stx *.syr *.tim *.tspec *.vm6 *.xml *.xrpt *.xst *.xsvf

FORCE:
