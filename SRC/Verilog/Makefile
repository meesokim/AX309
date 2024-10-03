DEVICE = xc6slx9-2-ftg256
# TITLE := $(shell echo $(shell basename $(CURDIR)) | cut -c 4-)
TITLE := $(patsubst %.xise,%,$(wildcard *.xise))

IMPACT_CMD_FILE := _impact.cmd
UCF_FILE := $(TITLE).ucf
UT_FILE  := $(TITLE).ut
PRJ_FILE := $(TITLE).prj
XST_FILE := $(TITLE).xst

ifeq ($(wildcard verilog_files),)
	SOURCES := $(strip $(shell cat $(PRJ_FILE) | grep -oE '[^[:blank:]]+[[:blank:]]*$$' | tr -d '"' ))
else
    SOURCES := $(shell cat verilog_files)
endif

TOP := $(strip $(shell \
	cat $(XST_FILE) | grep "[-]top" | sed s/-top//g ))
	
TOP_FILE := $(filter %$(TITLE).v,$(SOURCES))

ifneq ($(wildcard ucf_file),)
	UCF_FILE := $(shell cat ucf_file)
endif 

#ifneq "$(basename $(notdir $(TOP_FILE)))" "$(TOP)"
#	$(error Design top must have the same name as top-level source file)
#endif

default: burn

synth: $(TITLE).ngc $(TITLE).srp
ngdbuild: $(TITLE).ngd $(TITLE).bld
map: $(TOP)_map.ncd $(TOP).pcf
par: $(TOP).ncd $(TOP).unroutes $(TOP).par $(TOP).twr
bitgen: $(TOP).bit

.SECONDARY: $(TOP).ngc $(TOP).srp $(TOP).ngd $(TOP).bld $(TOP)_map.ncd 
.SECONDARY: $(TOP).pcf $(TOP).ncd $(TOP).unroutes $(TOP).par $(TOP).twr

#-----------------------------------------------------------------------------

%.ngc %.srp: $(subst $(TOP),%,$(TOP_FILE)) $(SOURCES) $(PRJ_FILE) $(XST_FILE)
	@rm -f $*.ngc $*.srp
	mkdir -p xst/projnav.tmp
	xst -intstyle silent  -ifn $(filter %.xst,$^)

#-----------------------------------------------------------------------------

%.ngd %.bld: %.ngc $(UCF_FILE)
	@rm -f $*.ngd $*.bld
	ngdbuild -intstyle silent -dd _ngo -sd ipcore_dir -nt timestamp -uc \
		$(filter %.ucf,$^) -p $(DEVICE) $< $(TOP)

#-----------------------------------------------------------------------------

%_map.ncd %.pcf: %.ngd
	@rm -f $*_map.ncd $*.pcf
	map -w -p $(DEVICE) -ir off -pr b -detail \
	-ol std -logic_opt off -c 100 -o $*_map.ncd $*.ngd $*.pcf

#-----------------------------------------------------------------------------

%.ncd %.unroutes %.par %.twr: %_map.ncd $(TOP).pcf
	@rm -f $*.ncd $*.unroutes $*.par $*.twr
	par -w -ol high $< $@ $(filter %.pcf,$^)
	trce -fastpaths -xml $(TITLE).twx -e $*.ncd $*.pcf

#-----------------------------------------------------------------------------

%.bit: %.ncd $(TOP).unroutes $(TOP).twr $(UT_FILE)
	@rm -f $@
	@echo "---------------------------------------------------------"
	@echo "Checking design for timing errors and unroutes..."
	@grep -i "all signals are completely routed" $(filter %.unroutes,$^) 
	@grep -iq "timing errors:" $(filter %.twr,$^); \
	if [ $$? -eq 0 ]; then \
		grep -i "timing errors: 0" $(filter %.twr,$^); \
		exit $$?; \
	fi
	@echo "Design looks good. Generating bitfile."
	@echo "---------------------------------------------------------"
	bitgen -f $(UT_FILE) $*.ncd $@

#-----------------------------------------------------------------------------

burn: $(TOP).bit $(IMPACT_CMD_FILE)
	impact -batch $(IMPACT_CMD_FILE)

show:
	@echo SOURCES $(SOURCES)
	@echo TOP $(TOP)
	@echo TITLE $(TITLE)
	@echo TOP_FILE $(TOP_FILE)
	@echo UCF_FILE $(UCF_FILE)
	@echo XST_FILE $(XST_FILE)
	@echo PRJ_FILE $(PRJ_FILE)
#-----------------------------------------------------------------------------

CLEAN_EXTS := .bgn .bit _bitgen.xwbt .bld .drc .lso _map.map _map.mrp _map.ncd
CLEAN_EXTS += _map.ngm _map.xrpt .ncd .ngc .ngd _ngdbuild.xrpt .ngr .pad
CLEAN_EXTS += _pad.csv _pad.txt .par _par.xrpt .pcf .ptwx .srp _summary.xml
CLEAN_EXTS += .twr .twr_pad.txt .twx .unroutes _usage.xml .xpi _xst.xrpt

clean:
	rm -f $(foreach x,$(CLEAN_EXTS),$(TOP)$(x))
	rm -f par_usage_statistics.html webtalk.log
	rm -f usage_statistics_webtalk.html $(TITLE)_envsettings.html $(TITLE)_summary.html 
	rm -f *.cmd_log
	rm -f '#Makefile#' '.#Makefile'
	rm -f _impactbatch.log
	rm -rf _ngo xlnx_auto_0_xdb  _xmsgs xst
