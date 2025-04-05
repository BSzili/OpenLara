ROOTDIR = /opt/amiga

TARGET = OpenLara
BUILD = build
SOURCES = . asm ../../fixed

PREFIX = $(ROOTDIR)/bin/m68k-amigaos-
CC = $(PREFIX)gcc
CXX = $(PREFIX)g++
CPP = $(PREFIX)cpp
AS = $(ROOTDIR)/bin/vasmm68k_mot
LD = $(PREFIX)ld
STRIP = $(PREFIX)strip

CC_VER := $(shell $(CC) -dumpversion)

#LIBPATH = -L$(ROOTDIR)/lib
INCPATH = -I. -I../../fixed

CFLAGS = -m68020 -Wall -Wstack-usage=1024 -c
# -g
CFLAGS += -O2 -fbbb=- -fomit-frame-pointer -DNDEBUG
#CFLAGS += -save-temps
#CFLAGS += -DPROFILING
CXXFLAGS = $(CFLAGS) -fno-rtti -fno-exceptions
LDFLAGS = -m68020 -Wl,-Map=$(BUILD)/output.map -fno-rtti -fno-exceptions
# -nostdlib
ASFLAGS = -Fhunk -m68020 -quiet

DD = dd
RM = rm -f

FILES_AS = $(foreach dir, $(SOURCES), $(wildcard $(dir)/*.s))
FILES_CC = $(foreach dir, $(SOURCES), $(wildcard $(dir)/*.c))
FILES_XX = $(foreach dir, $(SOURCES), $(wildcard $(dir)/*.cpp))

LIBS = $(LIBPATH) -ldebug
# -lm
OBJS =  $(addprefix $(BUILD)/, $(notdir $(FILES_AS:%.s=%.o)))
OBJS += $(addprefix $(BUILD)/, $(notdir $(FILES_CC:%.c=%.o)))
OBJS += $(addprefix $(BUILD)/, $(notdir $(FILES_XX:%.cpp=%.o)))

.PHONY: dump clean

all: $(BUILD) $(TARGET)

dump:
	@[ -d dump ] || mkdir -p dump
	$(CXX) $(CFLAGS) $(INCPATH) -S -o dump/main.s main.cpp
	$(CXX) $(CFLAGS) $(INCPATH) -S -o dump/render.s render.cpp
	$(CXX) $(CFLAGS) $(INCPATH) -S -o dump/sound.s sound.cpp
	$(CXX) $(CFLAGS) $(INCPATH) -S -o dump/common.s ../../fixed/common.cpp

$(BUILD):
	@[ -d $@ ] || mkdir -p $@

$(TARGET): $(OBJS)
	$(CXX) $(LDFLAGS) $(OBJS) $(LIBS) -o $(TARGET)
	$(STRIP) $(TARGET)

$(BUILD)/%.o: %.s
	$(AS) $(ASFLAGS) $(INCPATH) -o $@ $<

$(BUILD)/%.o: asm/%.s
	$(CPP) $(INCPATH) -o $(BUILD)/$(notdir $<) $<
	$(AS) $(ASFLAGS) $(INCPATH) -o $@ $(BUILD)/$(notdir $<)

$(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) $(INCPATH) -o $@ $<

$(BUILD)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCPATH) -o $@ $<

$(BUILD)/%.o: ../../fixed/%.cpp
	$(CXX) $(CXXFLAGS) $(INCPATH) -o $@ $<

clean:
	$(RM) $(BUILD)/* $(TARGET)
