/*
*/
//#include <climits.h>
#include <limits.h>
//#include <cstdlib.h>
//#include <cstring.h>
#include <ctype.h>
#include <fcntl.h>
#include <getopt.h>
//#include <c++/3.4.6/backward/iostream.h>
#include <malloc.h>
#include <math.h>
#include <memory.h>
//#include <ostream.h>
//#include <sstream.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <libgen.h>
#include <regex.h>

//#include <kvsstring_c.h>
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: kvsstring_c.h 78 2010-09-24 20:14:30Z schumack $ 
#ifndef _kvsstring
#define _kvsstring

//#include <kvstypes.h>
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: kvstypes.h 79 2010-09-24 20:14:31Z schumack $ 
#ifndef __kvstypes__
#define __kvstypes__

#define TRUE    1
#define FALSE   0
#define YES     1
#define NO      0
#define ERROR   (-1)
#define ERR     (-1)
#define READ    0
#define WRITE   1

#define LENGTHLSTRING 512
#define LENGTHLSTRINGINIT LENGTHLSTRING + 1

#define LENGTHSSTRING 80
#define LENGTHSSTRINGINIT LENGTHSSTRING + 1

typedef short   Boolean;
typedef char    stringS[LENGTHSSTRINGINIT];
typedef char    stringL[LENGTHLSTRINGINIT];
typedef double* coordArray;

#define SEEK_CUR 1

#define BUFSIZE     100
#define SIZE_FOREST 37

#define strEqual(s1, s2)   ( ! strcmp(s1, s2) )


typedef struct sort_linest 
{
    char*  strng;
    struct sort_linest* linkr;
} sort_linest;

typedef struct synonymForestMember 
{
    char*    name;
    char*    synonym;
    struct synonymForestMember* linkl;
    struct synonymForestMember* linkr;
}  synonymForestMember;

typedef struct GPO {  
    char*       name;
    char*       synonym;
    Boolean     Switch;
    int         Int;
    double      Double;
    struct GPO* headSynonym;
    struct GPO* linkl;
    struct GPO* linkr;
} GPO;

typedef GPO **GPOforest;
typedef GPO *GPOtree;

#endif


extern void    copy_array(float *a1, float *a2, int n);
extern char*   expandPosIntRange(char *input, char *output);
extern char*   fillCharArray(char *string, char character, int arr_length);
extern int     get_delim_field(char *string, char *field_string, char character, int position);
extern int     get_field(char *string, char *field_string, int position);
extern char*   get_field_number(char *string, char *field_string, int fieldNumber);
extern int     get_field_pos(char *string, int field, int position);
extern int     getargs(char *args[][80]);
extern void    getbody(char *input, char *output);
extern int     gsub(char *match, char *replacement, char *string);
extern int     gsubi(char *match, char *replacement, char *string);
extern char*   hexstopadedbins(char *string, char *binarystring, int numberofbits);
extern int     isdecint(char *string);
extern Boolean isfloat(char *string);
extern Boolean ishexint(char *string);
extern int     itobs(int i, char *bitstring);
extern void    legalstring(char *sinput, char *soutput, int maxlength, char fillerc);
extern int     lexidex(int y, int *array);
extern Boolean match_string(char *master, char *string, char option);
extern int     numfields(char *string);
extern char*   padCharArray(char *string, char character, int start, int arr_length);
extern char*   revstring(char *string, char *reversed);
extern char*   sGetWordPart(char *string, char *word, int position, int startOrEnd);
extern char*   sRemoveLeadingSpaces(char *parent, char *child);
extern char*   sRemoveSpaces(char *parent, char *child);
extern char*   sRemoveTrailingSpaces(char *parent, char *child);
extern char*   sRemoveWhiteSpace(char* parent, char* child);
extern char*   sRemoveTrailingZeros(char* parent, char* child);
extern char*   scolumn(char *string, char *control);
extern void    sdelcr(char *string);
extern char*   sdup(char *string);
extern int     sexpcmp(char *s1, char *s2);
extern int     sfind(char *string, char *line, char option);
extern int     sfindlast(char *string, char *line, char option);
extern char**  sget_argvs(char *string);
extern int     sgetword(char *string, char *word, int lim);
extern int     shexcmp(char *s1, char *s2);
extern char*   sintonly(char *parent, char *child);
extern int     sislower(char *string);
extern int     sisupper(char *string);
extern char    slastNonSpacec(char *string);
extern char*   smakealnum(char *parent, char *child);
extern int     snumc(char *string, char c);
extern int     snumcmp(char *s1, char *s2);
extern void    sortfile(char *options);
extern int     soverlap(char *string1, char *string2);
extern int     spatrep(char *string, char *pattern, char *replacement, int num_to_replace, Boolean ignore_case);
extern int     spatrepcol(char *string, char *pattern, char *replacement, int start_column, int num_to_replace, Boolean ignore_case, int number_replaced);
extern int     sposc(char *string, char c);
extern int     sposlastc(char *string, char c);
extern int     sposnextc(char *string, char c, int previousPosition);
extern char*   sprefix(char *prefix_string, char *string);
extern char*   sremovec(char *parent, char *child, char character);
extern char*   srepc(char *parent, char *child, char character, char replacement);
extern char*   sreppunct(char *parent, char *child, char replacement);
extern char*   sspacemin(char *parent, char *child);
extern char*   stoupper(char *string, char *upstring);
extern void    str_qsort(struct sort_linest **v, int left, int right, int (*comparison)(), int start_field, int end_field);
extern char*   strip_version(char *input, char *output);
extern int     sub(char *match, char *replacement, char *string);
extern int     subi(char *match, char *replacement, char *string);
extern char*   substring(char *parent, char *child, int start, int end);
extern void    swap(void *v[], int i, int j);
extern int     wildInLine(char *wildToFind, char *line, Boolean ignore_case);
extern int     wild_match(char *string, char *wildstring, int ignore_case);
extern void    write_sortfile_help(void);

#endif


		   //#include <gdsStream.h>
// Copyright 1995-2014 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: gdsStream.h 95 2014-12-08 17:16:36Z schumack $
#ifndef _gdsStream__
#define _gdsStream__

#define NUMGDSLAYERS 1024
#define MAXPAIRSXY 8191     //  int(0xffff / 8) -> 0xffff - 4 byte record header / 4 bytes per int
//G_epsilon: to take care of floating point representation problems
#define G_epsilon 0.00005

class GDSFILE
{
protected:
    char*   LibName;
    char*   FileName;
    char*   CurrentStrName;
    time_t  Time_val;
    char    Record[204800];     //100x 2048 for super large boundaries ...
    int     Eof;                // are we at the End Of File?
    int     EndOfLib;           // are we at the End Of Lib?
    int     Length;             //current record length
    int     Rectyp;             //current record type
    int     Dattyp;             //current data type
    char    Buffer[204800];
    int     Fd;                 // current file descriptor
    int     Writtn;             // 1 = write, 0 = read
    int     Ptr;                // current pointer in buffer
    short   Glayers[NUMGDSLAYERS];
    short   Tlayers[NUMGDSLAYERS];
    short   LayerDataTypes[NUMGDSLAYERS][NUMGDSLAYERS];
    short   LayerTextTypes[NUMGDSLAYERS][NUMGDSLAYERS];

    void    endEl(); // end of element
public:
    GDSFILE(char* fileName, int readOrWrite); // constructor to open (create if WRITE) stream file (calls opstrm())
    void    opstrm();                 // open stream file
    int     rdstrm();                 // read Record from stream file
    void    wrstrm();                 // write Record to stream file
            // write external record to stream file, Rectyp,Dattyp,Length taken from
            // another stream file (used when changing XY value for instance)
    void    wrstrm(char record[204800], GDSFILE* gdsfile);
            // write external record to stream file, Rectyp,Dattyp,Length taken from args
    void    wrstrm(char record[204800], int Rectyp, int Dattyp, int Length);
    void    cpstrm(GDSFILE* gdsfile); // cp Record from one GDSFILE to another
    void    cpend(GDSFILE* gdsfile);  // cp remaining bytes after ENDLIB from one GDSFILE to another
    void    clstrm();                 // close stream file

    void    initLib(char *library, double dbu_uu, double dbu_m, int myear, int mmon, int mmday, int mhour, int mmin, int msec, int ayear, int amon, int amday, int ahour, int amin, int asec, int version);
    void    initLib(char *library, double dbu_uu, double dbu_m, int myear, int mmon, int mmday, int mhour, int mmin, int msec, int ayear, int amon, int amday, int ahour, int amin, int asec);
    void    initLib(char* library, double dbu_uu, double dbu_m);
    void    initLib(char* library);   //uses dbu_uu==1.0e-3 and dbu_m==1.0e-9
    void    endLib();                 //write end of library record
    char*   libName();                //get stored LibName
    void    libName(char* name);      //store LibName
    void    copyRecord(char* copy);   //copy current record to "copy"

    void    beginStr(char* str_name); //open a new structure
    void    beginStr(char *str_name, int myear, int mmon, int mmday, int mhour, int mmin, int msec, int ayear, int amon, int amday, int ahour, int amin, int asec);

    void    endStr();                 //close a structure

    int     roundInt(int input, int grid);
    // place a structure reference
    void    putSref(char* sname,unsigned short ref,double mag,double angle,double x_coord,double y_coord,int propIndex,int propNumArray[],char propValueArray[][LENGTHLSTRING],double dbu_uu);
    void    putSref(char* sname, unsigned short ref, double mag, double angle, double x_coord, double y_coord, double dbu_uu);
    void    putSref(char* sname, unsigned short ref, double mag, double angle, double x_coord, double y_coord); //default uu==0.001
    // place an array reference
    void    putAref(char*  sname,unsigned short ref,double mag,double angle,short  col,short  row,double x1,double y1,double x2,double y2,double x3,double y3,int propIndex,int propNumArray[],char propValueArray[][LENGTHLSTRING],double dbu_uu);
    void    putAref(char* sname, unsigned short ref, double mag, double angle, short col, short row, double x1, double y1, double x2, double y2, double x3, double y3, double dbu_uu);
    void    putAref(char* sname, unsigned short ref, double mag, double angle, short col, short row, double x1, double y1, double x2, double y2, double x3, double y3); //default uu==0.001

    // place a rectangle
    void    putRt(int layer, int datatyp, double minX, double minY, double maxX, double maxY, double dbu_uu);
    void    putRt(int layer, int datatyp, double minX, double minY, double maxX, double maxY); //default uu==0.001
    // place a text
    void    putText(unsigned short layer, unsigned short ref, double mag, double angle, double x, double y, char* txt, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double dbu_uu);
    void    putText(unsigned short layer, unsigned short ref, double mag, double angle, double x, double y, char* txt, double dbu_uu);
    void    putText(unsigned short layer, unsigned short ref, double mag, double angle, double x, double y, char* txt); //default uu==0.001
    void    putText(unsigned short layer, unsigned short textType, unsigned short fontType, char* textJust, unsigned short pathType, double width, unsigned short ref, double mag, double angle, double x, double y, char* txt); //default uu==0.001
    void    putText(unsigned short layer, unsigned short textType, unsigned short fontType, char* textJust, unsigned short pathType, double width, unsigned short ref, double mag, double angle, double x, double y, char* txt, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double dbu_uu);
    void    putText(unsigned short layer, unsigned short textType, unsigned short fontType, char* textJust, unsigned short pathType, double width, unsigned short ref, double mag, double angle, double x, double y, char* txt, double dbu_uu);

    // place a boundary using arrays of doubles and props
    int     putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double dbu_uu);
    int     putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING]); //default uu==0.001
    // place a boundary using arrays of doubles
    int     putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, double dbu_uu);
    int     putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert); //default uu==0.001
    // place a boundary using arrays of ints
    int     putBndInt(int layer, int datatyp, int xArray[], int yArray[], int nVert);
    // place a path using arrays of ints
    int     putPathInt(int layer, int datatyp, int width, int xArray[], int yArray[], int nVert);
    // place a path using arrays of doubles
    int     putPathDbl(int layer, int datatyp, int pathtyp, double width, double bgnextn, double endextn, double xArray[], double yArray[], int nVert, double dbu_uu);
    int     putPathDbl(int layer, int dataTyp, int pathTyp, double width, double bgnExtn, double endExtn, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double uUnits);
    int     putPathDbl(int layer, int datatyp, int pathtyp, double width, double bgnextn, double endextn, double xArray[], double yArray[], int nVert); //default uu==0.001

    int     endoflib(); // are you at END OF LIB?
    int     eof();      // are you at EOF?
    int     rectyp();   // retrive current rectype
    void    rectyp(int);// set current rectype
    int     dattyp();   // retrive current dataType
    void    dattyp(int);// set current dataType
    int     length();   // retrive length of current record
    void    length(int);// set length of current record
    char*   record();   // return current record
    char*   fileName(); // return FileName of stream file.

    void    foundGraphicsLayer(short layerFound);
    void    foundLayerDatatype(short layerFound, short dataTypeFound);
    int     gLayer(short layerNum);    // does this graphics layer exist in stream file?
    int     layerDataType(short layer, short dataType); // does this graphics layer / datatype combo exist?

    void    foundTextLayer(short layerFound);
    void    foundLayerTexttype(short layerFound, short textTypeFound);
    int     tLayer(short layerNum);   // does this text layer exist in stream file?
    int     layerTextType(short layer, short textType); // does this text layer / datatype combo exist?;

    double  getDbl();                       // get double
    double  getDbl(int offset);             // get double at specified offset
    void    putDbl(double dbl, int offset); // put double at specified offset

    int     getI16();                               // get 16 bit integer
    int     getI16(int offset);                     // get 16 bit integer at specified offset
    void    putI16(unsigned short i16, int offset); // put 16 bit integer at specified offset

    int     getI32();                     // get 32 bit integer
    int     getI32(int offset);           // get 32 bit integer at specified offset
    void    putI32(int i32, int offset);  // put 32 bit integer at specified offset

    void    copy(char src_rec[], char dst_rec[], int  num);
    int     iround(long int number, int places);
} //end class GDSFILE

;
//extern foobar(void);
/*************************************************************************************
 * CALMA STREAM FORMAT
 *
The stream format file is composed of variable length records. The mininum
length record is 4 bytes. The 1st 2 btyes of a record contain a count (in 8 bit
bytes) of the total record length.  The 3rd byte of the header is the record
type. The 4th byte describes the type of data contained w/in the record. The
5th through last bytes are data.

If the output file is a mag tape, then the records of the library are written
out in 2048-byte physical blocks. Records may overlap block boundaries.

A null word consists of 2 consecutive zero bytes. Use null words to fill the
space between:
    o the last record of a library and the end of its block
    o the last record of a tape in a mult-reel stream file.

DATA TYPE        VALUE  RECORD
---------        -----  -----------------------
no data present     0   4bytes long
Bit Array           1   2bytes long
2byte Signed Int    2  SMMMMMMM MMMMMMMM  -> S - sign ;  M - magnitude.
                       Twos complement format, with the most significant byte first.
                       I.e.
                        0x0000 = 1
                        0x0020 = 2
                        0x0089 = 137
                        0xffff = -1
                        0xfffe = -2
                        0xff77 = -137

4byte Signed Int    3  SMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
8byte Real          5  SEEEEEEE MMMMMMMM MMMMMMMM MMMMMMMM E-expon in excess-64 representation
                       MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
                       Mantissa -> pos fraction >=1/16 and <1 bit 8 = 1/2, 9=1/4 etc...
                        The first bit is the sign (1 = negative), the next 7 bits
                        are the exponent, you have to subtract 64 from this number to get the real
                        value. The next three bytes are the mantissa, divide by 2^24 to get the
                        denominator.
                        value = (mantissa/(2^24)) * (16^(exponent-64))
string              6  odd length strings must be padded w/ null character and byte count++

*****************************************************************************/

/****************************************************************************
 * CALMA STREAM SYNTAX
 *
 <STREAM FORMAT>::=     HEADER BGNLIB [LIBDIRSIZE] [SRFNAME] [LIBSECR]
                        LIBNAME [REFLIBS] [FONTS] [ATTRTABLE] [GENERATIONS]
                        [<FormatType>] UNITS {<structure>}* ENDLIB

 <FormatType>::=        FORMAT | FORMAT {MASK}+ ENDMASKS

 <structure>::=         BGNSTR STRNAME [STRCLASS] {<element>}* ENDSTR

 <element>::=           {<boundary> | <path> | <SREF> | <AREF> | <text> |
                         <node> | <box>} {<property>}* ENDEL

 <boundary>::=          BOUNDARY [ELFLAGS] [PLEX] LAYER DATATYPE XY

 <path>::=              PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE]
                        [WIDTH] XY

 <SREF>::=             SREF [ELFLAGS] [PLEX] SNAME [<strans>] XY

 <AREF>::=             AREF [ELFLAGS] [PLEX] SNAME [<strans>] COLROW XY

 <text>::=             TEXT [ELFLAGS] [PLEX] LAYER <textbody>

 <textbody>::=         TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY
                       STRING

 <strans>::=           STRANS [MAG] [ANGLE]

 <node>::=             NODE [ELFLAGS] [PLEX] LAYER NODETYPE XY

 <box>::=              BOX [ELFLAGS] [PLEX] LAYER BOXTYPE XY

 <property>::=         PROPATTR PROPVALUE

****************************************************************************/

// CALMA STREAM RECORD DATATYPES
#define  NO_DATA       0
#define  BIT_ARRAY     1
#define  INTEGER_2     2
#define  INTEGER_4     3
#define  REAL_4        4
#define  REAL_8        5
#define  ACSII_STRING  6

// CALMA STREAM RECORD TYPES
#define  HEADER         0  // 2-byte Signed Integer
#define  BGNLIB         1  // 2-byte Signed Integer
#define  LIBNAME        2  // ASCII String
#define  UNITS          3  // 8-byte Real
#define  ENDLIB         4  // no data present
#define  BGNSTR         5  // 2-byte Signed Integer
#define  STRNAME        6  // ASCII String
#define  ENDSTR         7  // no data present
#define  BOUNDARY       8  // no data p/resent
#define  PATH           9  // no data present
#define  SREF          10  // no data present
#define  AREF          11  // no data present
#define  TEXT          12  // no data present
#define  LAYER         13  // 2-byte Signed Integer
#define  DATATYPE      14  // 2-byte Signed Integer
#define  WIDTH         15  // 4-byte Signed Integer
#define  XY            16  // 2-byte Signed Integer
#define  ENDEL         17  // no data present
#define  SNAME         18  // ASCII String
#define  COLROW        19  // 2-byte Signed Integer
#define  TEXTNODE      20  // no data present
#define  NODE          21  // no data present
#define  TEXTTYPE      22  // 2-byte Signed Integer
#define  PRESENTATION  23  // Bit Array
#define  SPACING       24  // discontinued
#define  STRING        25  // ASCII String
#define  STRANS        26  // Bit Array
#define  MAG           27  // 8-byte Real
#define  ANGLE         28  // 8-byte Real
#define  UINTEGER      29  // UNKNOWN User int, used only in V2.0
#define  USTRING       30  // UNKNOWN User string, used only in V2.0
#define  REFLIBS       31  // ASCII String
#define  FONTS         32  // ASCII String
#define  PATHTYPE      33  // 2-byte Signed Integer
#define  GENERATIONS   34  // 2-byte Signed Integer
#define  ATTRTABLE     35  // ASCII String
#define  STYPTABLE     36  // ASCII String "Unreleased feature"
#define  STRTYPE       37  // 2-byte Signed Integer "Unreleased feature"
#define  EFLAGS        38  // BIT_ARRAY  Flags for template and exterior data.  bits 15 to 0, l to r 0=template, 1=external data, others unused
#define  ELKEY         39  // INTEGER_4  "Unreleased feature"
#define  LINKTYPE      40  // UNKNOWN    "Unreleased feature"
#define  LINKKEYS      41  // UNKNOWN    "Unreleased feature"
#define  NODETYPE      42  // INTEGER_2  Nodetype specification. On GDSII this could be 0 to 63, LTL allows 0 to 255. Of course a 2 byte integer allows up to 65535...
#define  PROPATTR      43  // INTEGER_2  Property number.
#define  PROPVALUE     44  // STRING     Property value. On GDSII, 128 characters max, unless an SREF, AREF, or NODE, which may have 512 characters.
#define  BOX           45  // NO_DATA    The beginning of a BOX element. An unfilled boundary. Not used for IC polygon.
#define  BOXTYPE       46  // INTEGER_2  Boxtype specification.
#define  PLEX          47  // INTEGER_4  Plex number and plexhead flag. The least significant bit of the most significant byte is the plexhead flag.
#define  BGNEXTN       48  // INTEGER_4  Path extension beginning for pathtype 4 in CustomPlus. In database units, may be negative.
#define  ENDEXTN       49  // INTEGER_4  Path extension end for pathtype 4 in CustomPlus. In database units, may be negative.
#define  TAPENUM       50  // INTEGER_2  Tape number for multi-reel stream file.
#define  TAPECODE      51  // INTEGER_2  Tape code to verify that the reel is from the proper set. 12 bytes that are supposed to form a unique tape code.
#define  STRCLASS      52  // BIT_ARRAY  Calma use only.
#define  RESERVED      53  // INTEGER_4  Used to be NUMTYPES per GDSII Stream Format Manual, v6.0.
#define  FORMAT        54  // INTEGER_2  Archive or Filtered flag.  0: Archive 1: filtered
#define  MASK          55  // STRING     Only in filtered streams. Layers and datatypes used for mask in a filtered stream file. A string giving ranges of layers and datatypes separated by a semicolon. There may be more than one mask in a stream file.
#define  ENDMASKS      56  // NO_DATA    The end of mask descriptions.
#define  LIBDIRSIZE    57  // INTEGER_2  Number of pages in library director, a GDSII thing, it seems to have only been used when Calma INFORM was creating a new library.
#define  SRFNAME       58  // STRING     Sticks rule file name.
#define  LIBSECUR      59  // INTEGER_2  Access control list stuff for ancient CalmaDOS. INFORM used this when creating a new library. Had 1 to 32 entries with group numbers, user numbers and access rights.

#endif

//end

//#include <gcc4.h>
//for gcc rev 4 we need to include these...
// @(#) $Id: gcc4.h 68 2010-09-24 20:14:20Z schumack $ 


//  Textstring classes
#define  TEXT_NAME      0    //  Simple signal name, begins with alphabetic character
#define  TEXT_IPTAG     1    //  Begins with "&", an iptag
#define  TEXT_VMARKER   2    //  Begins with a number, probably a voltage marker, but should be neither of the above.
#define  TEXT_UNKNOWN   3    //  Something unidentified.

using namespace std;

static char   phyGdsFileArg[1024] = "";     //  PHY gds file name arg
static char   phyGdsFile[1024] = "";     //  PHY gds file name complete
static char   intGdsFileArg[1024] = "";     //  Interposer gds file name arg
static char   phyUnconnnectedOkFile[1024] = "";     //  File name of unconnectedOK list
static char   damnCloseOkFile[1024] = ""; 
static char   mapPrefix[1024] = ""; 
static char   intGdsFile[1024] = "";     //  Interposer gds file name complete
static char   phyCellArg[1024] = "";     //  PHY gds file name arg
static char   intCellArg[1024] = "";     //  Interposer gds file name arg
static char   phyPinTextLayerArg[20] = "";     //  PHY pin text layer arg
static char   intPinTextLayerArg[20] = "";     //  Interposer pin text layer arg
static char   phyOrientation[20] = "";
static char   phyOrigin[20] = "";
static double phyOriginXd=0.0, phyOriginYd=0.0;
static long   phyOriginX=0, phyOriginY=0;
static double bumpWindowSize=5.0;         //  Size of the window around a bump label to look for corresponding labels.
static long   bumpWindowDelta;
static char   pinMapfile[1024] = "";
static char   phyBoundaryLayer[20] = "";

static double phyBumpEdgeSetback = 100.0;   //  In the instance that the PHY boundary cannot be determined from a boundary layer, determine from the
                                           //  label field itself, applying this number as the spacing added to the inferred boundary.

//  Constants for the getopts 'val' value.
#define OPT_PHYGDS 1               // PHY gds file
#define OPT_INTGDS 2               // Interposer gds file
#define OPT_PHYPINTEXTLAYER 3      //  PHY Pin text layer
#define OPT_INTPINTEXTLAYER 4      //  Interposer pin text layer
#define OPT_PHYCELL 5              //  Name of top cell in PHY
#define OPT_INTCELL 6              //  Name of top cell in interposer
#define OPT_PHYORIENTATION 7
#define OPT_PHYORIGIN 8
#define OPT_PINMAPFILE 9
#define OPT_PHYBOUNDARYLAYER 10
#define OPT_HELP 11
#define OPT_PHYUNCONNECTEDOK 12
#define OPT_DAMNCLOSEOK 13
#define OPT_MAPPREFIX 14
#define OPT_DEBUG 15
#define OPT_OUTFILEROOT 16

static struct option long_options[] = {
  {"phyGds",           required_argument, 0, OPT_PHYGDS},             //  Phy GDS file
  {"intGds",           required_argument, 0, OPT_INTGDS},             //  Interposer GDS file
  {"phyPinTextLayer",  required_argument, 0, OPT_PHYPINTEXTLAYER},    //  Layer ("layer;texttype") for pin text in PHY)
  {"intPinTextLayer",  required_argument, 0, OPT_INTPINTEXTLAYER},    //  Layer ("layer;texttype") for pin text in interposer)
  {"phyCell",          required_argument, 0, OPT_PHYCELL},            //  top-level cellname for PHY
  {"intCell",          required_argument, 0, OPT_INTCELL},            //  top-level cellname for interposer
  {"phyOrientation",   required_argument, 0, OPT_PHYORIENTATION},     //  Orientation for phy (typically mirrored, die flipped over wrt interposer)
  {"phyOrigin",        required_argument, 0, OPT_PHYORIGIN},          //  Placement origin for PHY in interposer.
  {"pinMapfile",       required_argument, 0, OPT_PINMAPFILE},         //  File containing appings from phy to interposer name
  {"phyBoundaryLayer", required_argument, 0, OPT_PHYBOUNDARYLAYER},   //  PHY boundary layer, used to determine PHY footprint.
  {"phyUnconnOkFile",  required_argument, 0, OPT_PHYUNCONNECTEDOK},   //  File listing phy bumps by name and location that are OK to be unconnected.
  {"damnCloseOkFile",  required_argument, 0, OPT_DAMNCLOSEOK},   //  File listing phy bumps that are OK to be very close, (within 1 gds unit) but not exact
  {"mapPrefix",        required_argument, 0, OPT_MAPPREFIX},         //  Alternative to a map file; just assume a prefix on the phy bump name.
  {"help",             no_argument,       0, OPT_HELP},
  {"debug",            no_argument,       0, OPT_DEBUG},
  {"outFileRoot",      required_argument, 0, OPT_OUTFILEROOT},
  {0, 0, 0, 0}
};

extern void print_help();
extern void * myMalloc(size_t size);
extern void fmtCoord(long iVal, char *fVal);
extern int textConsistent(struct listRec *lRec);
extern int getLabelType(char *inString);
//extern double polygonArea(long *coordArray, int nCoords);
extern unsigned int isIntegerString(char *str);
extern unsigned int legalDatatype(long dataType);
extern unsigned int isPrBoundaryLayer(char *layerString);
extern bool CheckCoordsInsidePolygon( long int x, long int y, long int * xylist, int sizeOfArray );
extern char* mystrncpy(char *dest, char *src, size_t n);
extern bool CheckCoordsInsidePath( long int x, long int y, long int pathWidth, long int * xylist, int counter );
extern void dbgPrint(char *str);
extern struct geomRec *newGeomRec (long layer, long dataType, long *xyArray, int nXY);
extern struct gdsStruct *readGds(char *gdsFile, char *cellname, int processText, int processGeom, char *textLayer, char *boundaryLayer);
extern void stredit(char *string, char *oplistin);
extern void findExtraLabels(struct gdsStruct *gds);
extern void dumpTexts(struct gdsStruct *gds);
extern void findBumpMatches(struct gdsStruct *gds1, struct gdsStruct *gds2);
extern void applyMap(gdsStruct *gds, struct mapRec *mapList);
extern void processPhyBoundary(gdsStruct *phyGds);
extern unsigned int CheckRequiredArg(char *argName, char *argValue);

char *lcString(char *p) {
  char *plc;
  char *p1;
  plc = (char *)myMalloc(strlen(p)+1);
  p1 = plc;
  while (*p) *p1++ = tolower(*p++);
  return plc;
}

Boolean strEqualNocase(char *p1, char *p2) {
  // A case-insensitive string compare
  //printf("DBG strEqualNocase:  \"%s\" \"%s\"\n", p1, p2);
  while ((*p1 != '\0') && (*p2 != '\0')) {
    if (tolower(*p1++) != tolower(*p2++)) return 0;
  }

  if ((*p1 == '\0') && (*p2 == '\0')) return 1;
  return 0;
}


char *strsto(char *myString) {
  char *s;
  s = (char *) myMalloc(strlen(myString)+1);
  strcpy(s, myString);
  return s;
}

// global logFile
char msg[1024];
FILE *logFile = NULL;

static void logMsg(char *message) {
  if (logFile != NULL) {
    fprintf(logFile, "%s\n", message);
  }
  printf("%s\n", message);
}

static void logInfo(char *message) {
  if (logFile != NULL) {
    fprintf(logFile, "Info:  %s\n", message);
  }
  printf("Info:  %s\n", message);
}

static void logWarning(char *message) {
  if (logFile != NULL) {
    fprintf(logFile, "Warning:  %s\n", message);
  }
  printf("Warning:  %s\n", message);
}

static void logError(char *message) {
  if (logFile != NULL) {
    fprintf(logFile, "Error:  %s\n", message);
  }
  printf("Error:  %s\n", message);
  fflush(stdout);
}



#define MEMBLOCKSIZE 1048576000
struct textRec {
  long            layer;
  long            textType;
  long            x;
  long            y;
  long            tx;  //  X translated for orientation and origin in interposer space
  long            ty;  //  Y translated for orientation and origin in interposer space
  char           *text;
  char           *root;
  int            busbit;
  int            deadOn;  //  Set when matched bump coords exactly match
  int            damnClose;  //  Set when matched bump coords exactly match
  int            nameMismatch;
  char           *mapped;
  struct textRec *connText;
  struct textRec *next;
};

//  List element for map pairs.
struct mapRec {
  char *phyName;
  char *intName;
  unsigned hasBkt;
  struct mapRec *next;
};

struct geomRec {
  long            layer;
  long            dataType;
  long            width;  // Path only
  int             nCoords;
  long           *coords;
  unsigned int    isRect : 1;
  unsigned int    boundary : 1;
  unsigned int    path : 1;
  unsigned int    isPrBoundary : 1;
  // These are used when it's a simple rectangle
  long            minX;
  long            minY;
  long            maxX;
  long            maxY;
  int             textCount;
  struct listRec *textList;
  struct listRec *textListEnd;
  struct geomRec *next;
};

struct gdsStruct {
  char *fileName;
  char *topCell;
  struct textRec *textList;
  struct geomRec *geomList;
  double userUnits;
  double dbUnits;
  int precision;
  int nText;
  int nBoundary;
  int boundaryDefined;
  long minX;
  long minY;
  long maxX;
  long maxY;
  long tminX;  //  The above translated into interposer space
  long tminY;
  long tmaxX;
  long tmaxY;
} *phyGds, *intGds;

// Generic list structure
struct listRec {
  void *element;
  struct listRec *next;
};

char pinGeomDatatypeStr[1000] = "";  //  By default, only pay anntention to geomtries with datatype 0
int  pinGeomDatatype[1000];  //  By default, only pay anntention to geomtries with datatype 0
int  pinGeomDatatypeCount = -1;  //  This will get calculated.

//  Global values; These will be defined once gds's are read.
double  userUnits,
  epsilon;
int  precision = 0;

struct mapRec *mapList;
struct mapRec **mapListPtr = &mapList;
char thisProgram[2048];

struct textRec *unconnectOkList;
struct textRec **unconnectOkListPtr = &unconnectOkList;

struct textRec *damnCloseOkList;
struct textRec **damnCloseOkListPtr = &damnCloseOkList;

char outFileRoot[1024] = "", logFileName[2014];

FILE *openOutFile(char *fileClass, char *type) {
  char fileName[1024];
  sprintf(fileName, "%s.%s.%s", outFileRoot, fileClass, type);
  
  FILE *fptr;
  fptr = fopen(fileName, "w");
  if (fptr == NULL) {
    sprintf(msg, "Cound not open %s for write", fileName); logError(msg);
  }
  return fptr;
}

Boolean findInTextList(struct textRec *tRec, struct textRec *list) {
  struct textRec *p;

  for (p=list; (p!=NULL); p=p->next) {
    if (!strEqualNocase(tRec->text, p->text)) continue;
    if (tRec->x != p->x) continue;
    if (tRec->y != p->y) continue;
    return 1;
  }
  return 0;
}

Boolean debugMode = 0;

//////////////////////////////////////////////////////////////////////////////
// M A I N
//////////////////////////////////////////////////////////////////////////////
int main(int argc, char **argv)
{
  
  struct textRec *textList = NULL;
  struct geomRec *geomList = NULL;

  long *lp;
  int iXY;

  int       option_index = 0;
  int       c;
  char      stringName[1024];
  char      cellname[1024];
  unsigned int noPath = 0;  //  Skip paths when 
  unsigned int strict = 0;  // 
  
  // next line uses '@ ( # )' so the unix/linux 'what' command works on the executable
  //  cerr << "# ** gds2gdt @(#) Version " << sourceForgeVersion << " $Id: gds2gdt.C 95 2014-12-08 17:16:36Z schumack $ ** #" << endl; //using subversion props
  
  //  if((logFile = fopen(logFileName,"w")) == NULL) {
  //   cerr << "ERROR **** unable to create file " << logFileName << endl;
  //  exit(1);
  // }

  strcpy(thisProgram, argv[0]);
  
  
  unsigned argMask = 0;
  //args handling
  while (1) {
    /// Doing long args only, hence the "" optstring arg.
    c = getopt_long (argc, argv, "", long_options, &option_index);
    /* Detect the end of the options. */
    if (c == -1) { break; }
    switch (c) {
    case 0:
      break;
    case OPT_PHYGDS:
      strcpy(phyGdsFileArg, optarg);
      break;
    case OPT_INTGDS:
      strcpy(intGdsFileArg, optarg);
      break;
    case OPT_PHYPINTEXTLAYER:
      strcpy(phyPinTextLayerArg, optarg);
      break;
    case OPT_INTPINTEXTLAYER:
      strcpy(intPinTextLayerArg, optarg);
      break;
    case OPT_PHYCELL:
      strcpy(phyCellArg, optarg);
      break;
    case OPT_INTCELL:
      strcpy(intCellArg, optarg);
      break;
    case OPT_PHYORIENTATION:
      strcpy(phyOrientation, optarg);
      break;
    case OPT_PHYORIGIN:
      strcpy(phyOrigin, optarg);
      break;
    case OPT_PINMAPFILE:
      strcpy(pinMapfile, optarg);
      break;
    case OPT_PHYBOUNDARYLAYER:
      strcpy(phyBoundaryLayer, optarg);
      break;
    case OPT_HELP:
      print_help();
      exit (0);
      break;
    case OPT_DEBUG:
      debugMode = 1;
      break;
    case OPT_PHYUNCONNECTEDOK:
      strcpy(phyUnconnnectedOkFile, optarg);
      break;
    case OPT_DAMNCLOSEOK:
      strcpy(damnCloseOkFile, optarg);
      break;
    case OPT_MAPPREFIX:
      strcpy(mapPrefix, optarg);
      break;
    case OPT_OUTFILEROOT:
      strcpy(outFileRoot, optarg);
      break;
    default:
      exit (1);
    }
  }

  // Check for complete set of args
  unsigned int argOK = 1;
  argOK = argOK & CheckRequiredArg("intGds", intGdsFileArg);
  argOK = argOK & CheckRequiredArg("phyGds", phyGdsFileArg);
  argOK = argOK & CheckRequiredArg("phyPinTextLayer", phyPinTextLayerArg);
  argOK = argOK & CheckRequiredArg("intPinTextLayer", intPinTextLayerArg);
  argOK = argOK & CheckRequiredArg("phyCell", phyCellArg);
  argOK = argOK & CheckRequiredArg("intCell", intCellArg);
  argOK = argOK & CheckRequiredArg("phyOrientation", phyOrientation);
  argOK = argOK & CheckRequiredArg("phyOrigin", phyOrigin);
  //argOK = argOK & CheckRequiredArg("pinMapFile", pinMapfile);
  argOK = argOK & CheckRequiredArg("phyBoundaryLayer", phyBoundaryLayer);

  if (*outFileRoot == '\0') {
    // outFileRoot not specified on command line
    sprintf(outFileRoot, "%s_VS_%s", phyCellArg, intCellArg);
  }

  sprintf(logFileName, "%s.bumpcheck.log", outFileRoot);
  logFile = fopen(logFileName, "w");
  if (logFile == NULL) {
    sprintf(msg,"Could not open %s for write", logFileName); logWarning(msg);
  } else {
    sprintf(msg,"Opening logfile %s\n", logFileName); logInfo(msg);
  }
  
  if (!argOK) {
    sprintf(msg,"Exiting on missing required arg(s)"); logInfo(msg);
    exit(1);
  }
  //  Deal with phyOrientation
  stredit(phyOrientation, "UPCASE");

  //  Deal with phyOrigin
  //  BOZO:  No real error checking on the format of the arg.  Perhaps regular expressions.
  char *tok;
  char *endP;
  double xd=0.0, yd=0.0;
  if (phyOrigin[0] != 0) {
    //  Check the format of the origin.  Expecting xx.xxx,yyy.yy form.  Not sure how robust this is, but seems to work.
    int status;
    regex_t r;
    regmatch_t rm[3];
    char rs[] = "^(-?[0-9]+\\.?[0-9]*),(-?[0-9]+\\.?[0-9]*)$";
    // printf("rs = \"%s\"\n", rs);
    status = regcomp(&r, rs, REG_EXTENDED);
    status = regexec(&r, phyOrigin, 3, rm, 0);
    if (status != 0) {
      sprintf(msg,"phyOrigin \"%s\" not in expected format. xx.xxx,yy.yyy", phyOrigin); logError(msg);
      exit(1);
    }
    //   regexec matching:  The first one is the entire matched part. The second+ are the embedded () matches.
    //printf(" %d %d   %d %d  %d %d\n", rm[0].rm_so, rm[0].rm_eo, rm[1].rm_so, rm[1].rm_eo, rm[2].rm_so, rm[2].rm_eo);
    char *xs, *ys;
    xs = phyOrigin + rm[1].rm_so;
    *(xs + rm[1].rm_eo) = 0;
    ys = phyOrigin + rm[2].rm_so;
    *(ys + rm[2].rm_eo) = 0;  // Probably not necessary.
    //  printf("x2=%s, ys=%s\n", xs,ys);
    //  Can't convert these to int until gds's are read and units are known
    phyOriginXd = strtod(xs, NULL);
    phyOriginYd = strtod(ys, NULL);
    sprintf(msg,"phyOrigin:  %.4f,%.4f\n", phyOriginXd, phyOriginYd); logInfo(msg);
  }  
  realpath(phyGdsFileArg, phyGdsFile);
  realpath(intGdsFileArg, intGdsFile);
  char *phyBaseName;
  char *intBaseName;
  phyBaseName = basename(phyGdsFile);
  intBaseName = basename(intGdsFile);
  

  //  Deal with map file, which determines what pins on the phy side match those on the interposer side.
  FILE *map;
  FILE *uok = NULL;
  FILE *dcok = NULL;
  char line[1024];
  char *tok1, *tok2, *tok3;
  if (*pinMapfile != 0) {
    map = fopen(pinMapfile, "r");
    if (map == NULL) {
      sprintf(msg, "Cannot open %s for read", pinMapfile); logError(msg);
      perror(NULL);
      exit(1);
    }
    sprintf(msg, "Reading map file %s\n", pinMapfile); logInfo(msg);
    struct mapRec *m; 
    while ( fgets(line,1023,map) != NULL ) {
      stredit(line, "UNCOMMENT");
      tok1 = (char *) strtok(line, " \t\n");
      tok2 = (char *) strtok(NULL, " \t\n");
      if ((tok1!=NULL) && (tok2!=NULL)) {
	// Two tokens.  Save them.
	m = (struct mapRec *) myMalloc(sizeof(struct mapRec));
	m->phyName = lcString(tok1);
	m->intName = lcString(tok2);
	
	if (strchr(tok1, '[') == NULL) {m->hasBkt = 0;} else {m->hasBkt = 1;}
	m->next = NULL;
	*mapListPtr = m;
	mapListPtr = &(m->next);
      }
    }
    fclose(map);
  }
  
  if (*phyUnconnnectedOkFile != '\0') {
    //  Process unconnectedOK file
    uok = fopen(phyUnconnnectedOkFile, "r");
    if (uok == NULL) {
      sprintf(msg, "Cannot open %s for read",phyUnconnnectedOkFile); logError(msg);
      perror(NULL);
      exit(1);
    }
  }

  if (*damnCloseOkFile != '\0') {
    //  Process unconnectedOK file
    dcok = fopen(damnCloseOkFile, "r");
    if (dcok == NULL) {
      sprintf(msg, "Cannot open %s for read",damnCloseOkFile); logError(msg);
      perror(NULL);
      exit(1);
    }
  }

  //  Something really weird going on.  intGdsFile is somehow getting stepped on (flakily, adding some debug prints sometimes
  //  fixes this.  Anyway, that's the reason for making the copies, below.
  char *phyGdsFilename, *intGdsFilename;
  phyGdsFilename = strsto(phyGdsFile);
  intGdsFilename = strsto(intGdsFile);

  intGds = readGds(intGdsFilename, intCellArg, 1, 0, intPinTextLayerArg, "");
  sprintf(msg, "%d labels read from interposer\n", intGds->nText); logInfo(msg);
  //dumpTexts(intGds);

  phyGds = readGds(phyGdsFilename, phyCellArg, 1, 1, phyPinTextLayerArg, phyBoundaryLayer);
  sprintf(msg, "%d labels, %d boundary polygons read from phy\n", phyGds->nText, phyGds->nBoundary); logInfo( msg);


  // Contains two eight-byte real numbers. The first number is the size of a database unit in user units. The second number is the size of a database unit in meters.
  // For example, if you create a library with the default units (user unit = 1 micron and 1000 database units per user unit), the first number is .001, and the second
  // number is 1E-9. Typically, the first number is less than 1, since you use more than 1 database unit per user unit. To calculate the size of a user unit in meters,
  // divide the second number by the first.

  
  sprintf(msg, "Reconciling gds units"); logInfo(msg);
  int mul;
  textRec *t, *t1;
  geomRec *g;
  sprintf(msg, "Interposer units = %e, PHY units = %e.", intGds->dbUnits, phyGds->dbUnits); logInfo( msg);
  if (intGds->userUnits > phyGds->userUnits) {
    mul = (int) (intGds->userUnits/phyGds->userUnits);
    sprintf(msg, "Applying %d multiplier to interposer gds",mul); logInfo(msg);
    intGds->userUnits = phyGds->userUnits;
    intGds->dbUnits = phyGds->dbUnits;
    for (t=intGds->textList; (t!=NULL); t=t->next) {t->x *= mul; t->y *= mul;t->tx *= mul; t->ty *= mul;};
    for (g=intGds->geomList; (g!=NULL); g=g->next) {g->minX *= mul; g->minY *= mul;g->maxX *= mul; g->maxY *= mul;};
    precision = phyGds->precision;
    // BOZO:  Add coord mul for geom's if geoms ever come into play.
    
  } else if (intGds->userUnits < phyGds->userUnits) {
    mul = (int) (phyGds->userUnits/intGds->userUnits);
    sprintf(msg, "Applying %d multiplier to PHY gds.",mul);logInfo(msg);
    phyGds->userUnits = intGds->userUnits;
    phyGds->dbUnits = intGds->dbUnits;
    for (t=phyGds->textList; (t!=NULL); t=t->next) {t->x *= mul; t->y *= mul;t->tx *= mul; t->ty *= mul;};
    for (g=phyGds->geomList; (g!=NULL); g=g->next) {g->minX *= mul; g->minY *= mul;g->maxX *= mul; g->maxY *= mul;};
    precision = intGds->precision;
    // BOZO:  Add coord mul for geom's
  } else {
    sprintf(msg, "No modifications required.");logInfo(msg);
    precision = phyGds->precision;
  }
  logMsg("");

  // Now that gds's are in agreement, define global values.
  userUnits = phyGds->userUnits;
  epsilon = userUnits/2000.0;

  // Want to read this file here, after units are resolved, to convert to proper int units
  double x, y;
  long xi, yi;
  Boolean hit;
  struct textRec *u;
  if (uok != NULL) {
    while ( fgets(line,1023,uok) != NULL ) {
      stredit(line, "UNCOMMENT");
      stredit(line, "COLLAPSE");
      if (*line == '\0') continue;
      tok1 = (char *) strtok(line, ",");
      tok2 = (char *) strtok(NULL, ",");
      tok3 = (char *) strtok(NULL, ",");

      x = strtod(tok2, NULL);
      y = strtod(tok3, NULL);
      xi = long(floor( 0.5 + x/userUnits));
      yi = long(floor( 0.5 + y/userUnits));
      u = (struct textRec *) myMalloc(sizeof(struct textRec));
      u->text = strsto(tok1);
      u->x = xi;
      u->y = yi;
      u->next = NULL;
      //  The rest of the fields don't matter.
      struct textRec *unconnectOkList;
      *unconnectOkListPtr = u;
      unconnectOkListPtr = &(u->next);
    }
    fclose(uok);
  }

  struct textRec *d;
  if (dcok != NULL) {
    while ( fgets(line,1023,dcok) != NULL ) {
      stredit(line, "UNCOMMENT");
      stredit(line, "COLLAPSE");
      if (*line == '\0') continue;
      tok1 = (char *) strtok(line, ",");
      tok2 = (char *) strtok(NULL, ",");
      tok3 = (char *) strtok(NULL, ",");

      x = strtod(tok2, NULL);
      y = strtod(tok3, NULL);
      xi = long(floor( 0.5 + x/userUnits));
      yi = long(floor( 0.5 + y/userUnits));
      d = (struct textRec *) myMalloc(sizeof(struct textRec));
      d->text = strsto(tok1);
      d->x = xi;
      d->y = yi;
      d->next = NULL;
      //  The rest of the fields don't matter.
      struct textRec *damnCloseOkList;
      *damnCloseOkListPtr = d;
      damnCloseOkListPtr = &(d->next);
    }
    fclose(dcok);
  }

  processPhyBoundary(phyGds);

  char minXs[20], minYs[20], maxXs[20], maxYs[20];
  fmtCoord(phyGds->minX, minXs);
  fmtCoord(phyGds->minY, minYs);
  fmtCoord(phyGds->maxX, maxXs);
  fmtCoord(phyGds->maxY, maxYs);
  sprintf(msg, "PHY boundary:  ll = (%s,%s), ur=(%s,%s)", minXs, minYs, maxXs, maxYs); logInfo(msg);
  
  //  Handle the PHY orientation
  if (strEqualNocase(phyOrientation, "MY")) {
    //  Flipping phy in the X direction.  Y's unchanged, X's change sign
    sprintf(msg, "PHY orientation is MY, flipping signs of all X coordinates");logInfo(msg);
    for (t=phyGds->textList; (t!=NULL); t=t->next) {t->tx *= -1;};
    //  Note that min and max swap
    phyGds->tmaxX = phyGds->minX * -1;
    phyGds->tminX = phyGds->maxX * -1;
    phyGds->tminY = phyGds->minY;
    phyGds->tmaxY = phyGds->maxY;
  } else if (strEqualNocase(phyOrientation, "MX")) {
    //  Flipping phy in the Y direction.  X's unchanged, Y's change sign
    sprintf(msg, "PHY orientation is MX, flipping signs of all Y coordinates");logInfo(msg);
    for (t=phyGds->textList; (t!=NULL); t=t->next) {t->ty *= -1;};
    //  Note that min and max swap
    phyGds->tmaxY = phyGds->minY * -1;
    phyGds->tminY = phyGds->maxY * -1;
    phyGds->tminX = phyGds->minX;
    phyGds->tmaxX = phyGds->maxX;
  } else if (strEqualNocase(phyOrientation, "R0")) {
    //  No flipping.   No changes.
    sprintf(msg, "PHY orientation is R0, no coordinate modification");logInfo(msg);
    phyGds->tmaxX = phyGds->maxX;
    phyGds->tminX = phyGds->minX;
    phyGds->tminY = phyGds->minY;
    phyGds->tmaxY = phyGds->maxY;
  } else if (strEqualNocase(phyOrientation, "R180")) {
    //  Rotating 180. Flip both x and Y signs
    sprintf(msg, "PHY orientation is R180, flipping signs of all Y coordinates");logInfo(msg);
    for (t=phyGds->textList; (t!=NULL); t=t->next) {t->tx *= -1; t->ty *= -1;};
    phyGds->tmaxY = phyGds->minY * -1;
    phyGds->tminY = phyGds->maxY * -1;
    phyGds->tminX = phyGds->minX * -1;
    phyGds->tmaxX = phyGds->maxX * -1;
  } else if (*phyOrientation == 0) {
    //  Empty string, presume no flip, pretty unlikely.
    phyGds->tminX = phyGds->minX;
    phyGds->tmaxX = phyGds->maxX;
    phyGds->tminY = phyGds->minY;
    phyGds->tmaxY = phyGds->maxY;
    sprintf(msg, "PHY orientation is undefined, leaving coordinates unchanged");logInfo(msg);
  }
  else {
    sprintf(msg, "Error: Unrecognized orientation specifier \"%s\"", phyOrientation);logError(msg);
    exit(1);
  }

  // Handle phy origin in interposer space.
  phyOriginX = long(floor( 0.5 + phyOriginXd/userUnits));
  phyOriginY = long(floor( 0.5 + phyOriginYd/userUnits));
  phyGds->tminX += phyOriginX;
  phyGds->tmaxX += phyOriginX;
  phyGds->tminY += phyOriginY;
  phyGds->tmaxY += phyOriginY;
  
  for (t=phyGds->textList; (t!=NULL); t=t->next) {
    t->tx += phyOriginX;
    t->ty += phyOriginY;
  };

  // The x,y delta around a label to search for other labels.
  bumpWindowDelta = long (floor( 0.5 + ((bumpWindowSize*0.5)/userUnits)));

  //  Apply pin mapfile to get expected interposer bump name
  applyMap(phyGds, mapList);
  
  findExtraLabels(phyGds);
  findExtraLabels(intGds);

  findBumpMatches(phyGds, intGds);
  
  sprintf(msg, "Looking for matched bumps w/o exact text coordinate matches");logInfo(msg);
  FILE *damnCloseFile;
  FILE *nonExactFile;
  FILE *matchFile;
  FILE *exactFile;
  FILE *unmatchedIntFile;
  FILE *nameMismatchFile;
  
  nameMismatchFile = openOutFile("nameMismatch", "txt");
  if (nameMismatchFile == NULL) exit(1);

  damnCloseFile = openOutFile("damnClose", "txt");
  if (damnCloseFile == NULL) exit(1);

  nonExactFile = openOutFile("notClose", "txt");
  if (nonExactFile == NULL) exit(1);

  matchFile = openOutFile("matched", "txt");
  if (matchFile == NULL) exit(1);

  exactFile = openOutFile("exact", "txt");
  if (exactFile == NULL) exit(1);

  fprintf(damnCloseFile, "***  List of bumps matches within one gds unit, but not exact\n");
  fprintf(nonExactFile, "***  List of bumps matches within 5u,  but not exact or damn close\n");
  fprintf(matchFile, "***  List of all bump matches\n");
  fprintf(exactFile, "***  List of exact bump matches\n");
  fprintf(nameMismatchFile, "***  List of name mismatches\n");
  
  char xs[30], ys[30], xts[30], yts[30], x1s[30], y1s[30];
  int clean = 1;
  int nonExactCount = 0;
  int damnCloseCount = 0;
  int damnCloseWaivedCount = 0;
  int exactCount = 0;
  int matchCount = 0;
  int nameMismatchCount = 0;
  
  for (t=phyGds->textList; (t!=NULL); t=t->next) {
    if (t->connText == NULL) continue;   //  Skip non-matched bumps for now.
    fmtCoord(t->x, xs);
    fmtCoord(t->y, ys);
    fmtCoord(t->tx, xts);
    fmtCoord(t->ty, yts);
    fmtCoord(t->connText->x, x1s);
    fmtCoord(t->connText->y, y1s);
    if (t->nameMismatch) {
      nameMismatchCount++;
      fprintf(nameMismatchFile,"Bump name mismatch  %s @(%s,%s)-->(%s,%s) & %s @(%s,%s); expected %s\n", t->text, xs, ys, xts, yts, t->connText->text, x1s, y1s, t->mapped);
    } else {
      fprintf(matchFile, "Bump match  %s @(%s,%s)-->(%s,%s) & %s @(%s,%s)\n", t->text, xs, ys, xts, yts, t->connText->text, x1s, y1s);
      matchCount++;
    }
    if (t->deadOn) {
      fprintf(exactFile, "Exact bump match  %s @(%s,%s)-->(%s,%s) & %s @(%s,%s)\n", t->text, xs, ys, xts, yts, t->connText->text, x1s, y1s);
      exactCount++;
    } else if (t->damnClose) {
      if (findInTextList(t, damnCloseOkList)) {
	//  Waived.
	damnCloseWaivedCount++;
      } else {
	fprintf(damnCloseFile, "Damn-close label match  %s @(%s,%s)-->(%s,%s) & %s @(%s,%s)\n", t->text, xs, ys, xts, yts, t->connText->text, x1s, y1s);
      }
      damnCloseCount++;
    } else {
      fprintf(nonExactFile, "Non-exact bump label match  %s @(%s,%s)-->(%s,%s) & %s @(%s,%s)\n", t->text, xs, ys, xts, yts, t->connText->text, x1s, y1s);
      nonExactCount++;
    }
  }
    
  if (nonExactCount == 0) {
    logInfo("Non-exact bump match check Clean!\n");
  }

  fclose(damnCloseFile);
  fclose(nonExactFile);
  fclose(matchFile);
  fclose(exactFile);
  
  sprintf(msg, "%d bump matches.  See %s.matched.txt", matchCount, outFileRoot); logInfo(msg);
  sprintf(msg, "%d bump name mismatches.  See %s.nameMismatch.txt", nameMismatchCount, outFileRoot); logInfo(msg);
  sprintf(msg, "%d exact matches.  See %s.exact.txt", exactCount, outFileRoot); logInfo(msg);
  sprintf(msg, "%d damn-close (1 gds unit off) bump matches, %d waived. See %s.damnClose.txt for details.", damnCloseCount, damnCloseWaivedCount, outFileRoot); logInfo(msg);
  sprintf(msg, "%d not-that-close (< 5u) bump matches, See %s.notClose.txt for details.", nonExactCount, outFileRoot); logInfo(msg);
  
  logMsg("");
  logInfo("Checking for unconnected PHY bumps");
  FILE *noconnFile;
  
  noconnFile = openOutFile("unmatchedPhy", "txt");
  if (noconnFile == NULL) exit(1);

  fprintf(noconnFile, "***  List of unconnected PHY bumps\n");

  int unconnectedCount = 0;
  int unconnectedWaivedCount = 0;
  clean = 1;
  for (t=phyGds->textList; (t!=NULL); t=t->next) {
    if (t->connText == NULL) {
      //  A bump without a connection.  Check against the list of unconnetedOK bumps
      unconnectedCount++;
      struct textRec *u;
      hit = 0;
      for (u=unconnectOkList; (u!=NULL); u=u->next) {
	//printf("%s %s   %ld %ld  %ld %ld\n",t->text, u->text, t->x, u->x, t->x, u->y);
	if (!strEqualNocase(u->text, t->text)) continue;
	if (u->x != t->x) continue;
	if (u->y != t->y) continue;
	hit = 1;
	break;
      }
      fmtCoord(t->x, xs);
      fmtCoord(t->y, ys);
      fmtCoord(t->tx, xts);
      fmtCoord(t->ty, yts);
      if (hit) {
	unconnectedWaivedCount++;
	//printf("Info:  Unconnected OK PHY bump %s, @(%s,%s)-->(%s,%s)\n", t->text, xs, ys, xts, yts);
      } else {
	sprintf(msg, "Unconnected PHY bump %s, @(%s,%s)-->(%s,%s)", t->text, xs, ys, xts, yts);
	//logWarning(msg);
	fprintf(noconnFile, "%s\n", msg);
	clean = 0;
      }
    }
  }
  sprintf(msg, "%d unconnected PHY bumps found, %d waived. See %s.unmatchedPhy.txt for details", unconnectedCount, unconnectedWaivedCount, outFileRoot); logInfo(msg);
  if (clean) {
    logInfo("Unconnected PHY bump check: Clean!");
  }
  fclose(noconnFile);
  
  fmtCoord(phyGds->tminX, minXs);
  fmtCoord(phyGds->tminY, minYs);
  fmtCoord(phyGds->tmaxX, maxXs);
  fmtCoord(phyGds->tmaxY, maxYs);
  clean = 1;

  unmatchedIntFile = openOutFile("unmatchedInt", "txt");
  if (unmatchedIntFile == NULL) exit(1);
  fprintf(unmatchedIntFile, "***  List of unconnected Interposer bumps within PHY footprint\n");
  
  logMsg("");
  sprintf(msg, "Checking for unconnected interposer bumps withing PHY footprint (ll = (%s,%s), ur = (%s,%s))", minXs, minYs, maxXs, maxYs); logInfo(msg);
  int unconnectedIntCount = 0;
  clean = 1;
  for (t=intGds->textList; (t!=NULL); t=t->next) {
    if (t->connText == NULL) {
      //  Qualify with phy mbb
      if (t->x < phyGds->tminX) {continue;}
      if (t->x > phyGds->tmaxX) {continue;}
      if (t->y < phyGds->tminY) {continue;}
      if (t->y > phyGds->tmaxY) {continue;}
      //  A bump without a connection.
      fmtCoord(t->x, xs);
      fmtCoord(t->y, ys);
      unconnectedIntCount++;
      fprintf(unmatchedIntFile, "Unconnected interposer bump %s, @(%s,%s)\n", t->text, xs, ys);
      clean = 0;
    } else {}
  }

  sprintf(msg, "%d unconnected interposer bumps found. See %s.unmatchedInt.txt for details", unconnectedIntCount, outFileRoot); logInfo(msg);

  if (clean) {
    logInfo("Unconnected INT bump check: Clean!");
  }
  
  exit(0);
  
  
}  // end of main


struct gdsStruct *readGds(char *gdsFile, char *cellname, int processText, int processGeom, char *textLayer, char *boundaryLayer)  {
  
  int     i,
    rectyp,
    length,
    debug=0,
    extn,
    width,
    haveInputName=0,
    haveOutputName=0,
    inInFileName=0,
    inOutFileName=0,
    inPrecision=0,
    inProperty=0,
    inText=0,
    inTopCell=0,
    foundTopCell=0,
    inPath=0,
    inBoundary=0;
  char currentCell[1024];  // Name of current cell
  int currentLayer;
  int currentDatatype;
  int currentText[1024]; 
  char mdate[100];
  char adate[100];
  short   Ref, columns, rows, layer, dataType=0, textType, propAttr,
    year, month, day, hour, min, sec,
    version_num;
  double 
    dataBaseUnits=0.000000001, //1e-9 is common default
    Ang=0.0,
    Mag=0.0;
  char    oneChar,
    precisionString[128] = "0.001",
    bigString[204800] = "",
    string512[513] = ""; // 512 + room for '\0'
  stringL inputFile, outputFile, tmpFile, strname, tmpString1, tmpString2;
  stringS xstring, ystring, extnstring, wstring;
  long    xcoord=0,
    ycoord=0;
  long xyArray[2*MAXPAIRSXY];
  int nXY;  //  Number of XY's
  double  userUnits=0.001,           //1e-3 is common default
    epsilon=(userUnits/2000.0); //use to "fix" floating point error
  int  precision = 0;
  struct gdsStruct *gds;
  char layerDatatypeString[80];
  char layerTexttypeString[80];
  struct geomRec **geomListPtr;
  struct textRec **textListPtr;
  struct textRec *tRec;
  struct geomRec *gRec;
  int nPath=0, nText=0, nBoundary=0;
  int labelType;
  
  sprintf(msg, "Reading %s, topCell = %s, textLayer = \"%s\", boundaryLayer = \"%s\"", gdsFile, cellname, textLayer, boundaryLayer); logInfo( msg);

  gds = (struct gdsStruct *) myMalloc(sizeof(struct gdsStruct));
  gds->fileName = strsto(gdsFile);
  gds->topCell = strsto(cellname);
  gds->textList = NULL;    
  gds->geomList = NULL;    
  gds->boundaryDefined = 0;
  gds->minX = gds->minY = gds->maxX = gds->maxY = 0;
  
  geomListPtr = &(gds->geomList);
  textListPtr = &(gds->textList);

  GDSFILE gds2file(gdsFile, 0);

  gds2file.rdstrm();  // header
  version_num = gds2file.getI16();
  gds2file.rdstrm();  // bgnlib
  year  = gds2file.getI16(0);
  if (year < 999) year += 1900;
  month = gds2file.getI16(2);
  day   = gds2file.getI16(4);
  hour  = gds2file.getI16(6);
  min   = gds2file.getI16(8);
  sec   = gds2file.getI16(10);
  //  Last modification date
  sprintf(mdate, "%d-%02d-%02d %02d:%02d:%02d",year,month,day,hour,min,sec);
  //  printf("mdate = %s", mdate);
  year  = gds2file.getI16(12);
  if (year < 999) year += 1900;
  month = gds2file.getI16(14);
  day   = gds2file.getI16(16);
  hour  = gds2file.getI16(18);
  min   = gds2file.getI16(20);
  sec   = gds2file.getI16(22);
  // Last access date
  sprintf(adate, "%d-%02d-%02d %02d:%02d:%02d",year,month,day,hour,min,sec);
  //  printf("adate = %s\n", adate);
  while (! gds2file.eof()) {
    gds2file.rdstrm();
    rectyp = gds2file.rectyp();
    // printf("rectyp=%d, inBoundary=%d\n", rectyp, inBoundary);
    if ((rectyp < 0) || (rectyp > 59)) {
      sprintf(msg, "invalid record type:%d found in gds2 file. Note: May have just overflowed due to a super long record", rectyp); logError(msg);
      exit(1);
    }
    if (rectyp == LIBNAME) {
      gds2file.libName((char*) gds2file.record());
      strcpy(strname, gds2file.record());
    }
    else if (rectyp == BGNSTR) {
      year  = gds2file.getI16(0);
      if (year < 999) year += 1900;
      month = gds2file.getI16(2);
      day   = gds2file.getI16(4);
      hour  = gds2file.getI16(6);
      min   = gds2file.getI16(8);
      sec   = gds2file.getI16(10);
      year  = gds2file.getI16(12);
      if (year < 999) year += 1900;
      month = gds2file.getI16(14);
      day   = gds2file.getI16(16);
      hour  = gds2file.getI16(18);
      min   = gds2file.getI16(20);
      sec   = gds2file.getI16(22);
    }
    else if (rectyp == UNITS) {
      userUnits     = gds2file.getDbl();   // Calma default is 1.0e-3
      epsilon = (userUnits/2000.0);  //reset
      dataBaseUnits = gds2file.getDbl(8);  // Calma default is 1.0e-9
      //printf("userUnits = %e, dbUnits = %e\n", userUnits, dataBaseUnits);
      // I really don't get this
      if (userUnits != (dataBaseUnits*1000000.0)) 
	{
	  userUnits = dataBaseUnits*1000000.0;
	}
      if (precision <= 0) // then not set to positive integer on command line
	{
	  sprintf(tmpString1,"%0.8f",userUnits);
	  sRemoveTrailingZeros(tmpString1,precisionString);
	  precision = strlen(precisionString) - 2; // "0.001" -> 3, "0.05" -> 2
          if (precision < 0) precision = 0;
          //  This breaks if the unit is 1um or larger.
	}
      gds->userUnits = userUnits;
      gds->dbUnits = dataBaseUnits;
      gds->precision = precision;
    }
    else if (rectyp == STRNAME) {
      strcpy(strname, gds2file.record());
      strcpy(currentCell, strname);
      inTopCell = (strcmp(currentCell, cellname) == 0);
      if (inTopCell) {
	sprintf(msg, "Found top cell %s", cellname); logInfo(msg);
	foundTopCell=1;
      }
      //printf("STRNAME = %s, inTopCell = %d\n", strname, inTopCell);
    }
    else if (rectyp == BOUNDARY) {
      inBoundary = 1;
    }
    else if (rectyp == PATH) {
      inPath = 1;
    }
    else if ((rectyp == ENDEL) || (rectyp == ENDSTR) || (rectyp == ENDLIB)) {
      //printf("end %d, inTopCell=%d, inBoundary=%d, inText=%d\n", rectyp, inTopCell, inBoundary, inText);
     
      if (inTopCell) {
	if (rectyp == ENDSTR) {
	  //  Finished processing topcell.  May as well bug out.
	  // return gds;
	}
	sprintf(layerDatatypeString,"%d;%d", layer, dataType) ;
	sprintf(layerTexttypeString,"%d;%d", layer, textType) ;
	if (inBoundary && processGeom && (strcmp(layerDatatypeString, boundaryLayer) == 0)) {
	  //	  printf("topCell boundary, layer=%s\n", layerDatatypeString);
	  if (nXY >= 10) {
	    
	    gRec = newGeomRec(layer, dataType, xyArray, nXY);
	    gRec->boundary = 1;
	    // 
	    //  Make sure it's rectilinear and capture min/max x/y
	    long minX=0, minY=0, maxX=0, maxY=0;
	    gRec->isRect = 1;
	    if (nXY == 10) {
	      long xl, yl, x, y;
	      int i;
	      minX = maxX = xl = xyArray[0];
	      minY = maxY = yl = xyArray[1];
	      
	      for (i=2; (i<nXY); i+=2) {
		x = xyArray[i];
		y = xyArray[i+1];
		if ((x!=xl) && (y!=yl)) {
		  gRec->isRect = 0;
		}
		if (x<minX) {minX=x;}
		if (y<minY) {minY=y;}
		if (x>maxX) {maxX=x;}
		if (y>maxY) {maxY=y;}
		xl = x;
		yl = y;
	      }
	    }
	    else  {gRec->isRect=0;}
	    // If rectangular, save bounds for easy compare and don't save the whole XY list.
	    if (gRec->isRect) {
	      //		  printf("Info:  Rectangular boundary\n");
	      gRec->minX = minX;
	      gRec->minY = minY;
	      gRec->maxX = maxX;
	      gRec->maxY = maxY;
	    }
	    else {
	    }
	    *geomListPtr = gRec;
	    geomListPtr = &(gRec->next);
	    gds->nBoundary++;
	  }
	  else {
	  }
	}
	else if (inText && processText && (strcmp(layerTexttypeString, textLayer) == 0)) {
	  labelType = getLabelType(bigString);
	  //  Process simple names, or iptags, if enabled.
	  if (1) {
	    int x=0, y=0;
	    if (nXY == 2) {
	      x = xyArray[0];
	      y = xyArray[1];
	    }
	    // printf("topCell text  %d;%d (%d,%d) \"%s\"\n", layer, textType, x,y, bigString);
	    tRec = (struct textRec *) myMalloc(sizeof(struct textRec));
	    tRec->layer = layer;
	    tRec->textType = textType;
	    tRec->x = x;
	    tRec->y = y;
	    tRec->tx = x;
	    tRec->ty = y;
	    tRec->text = strsto(bigString);
	    stredit(tRec->text, "TRIM");  //  Ignoring any leading/trailing whitespace.
            
	    //strcpy(tRec->text, bigString);
	    tRec->mapped = NULL;
	    tRec->next = NULL;
	    tRec->busbit = -1;
	    tRec->root = NULL;
            tRec->nameMismatch = 0;
	    tRec->connText = NULL;
	    *textListPtr = tRec;
	    textListPtr = &(tRec->next);
	    gds->nText++;
            if (debugMode) {
              printf("\t%s\n", tRec->text);
            }
	  }
	}
	else if (inPath) {
	  //  Ignoring paths
	}
      }
      inBoundary = 0;
      inText = 0;
      inPath = 0;
    }
    else if (rectyp == COLROW) {}
    else if (rectyp == PATHTYPE) {}
    else if (rectyp == STRANS) {}
    else if (rectyp == PRESENTATION) {}
    else if (rectyp == TEXT) {
      inText = 1;
    }
    else if (rectyp == SREF) {}
    else if (rectyp == AREF) {}
    else if (rectyp == SNAME) {}
    else if ((rectyp == STRING) || (rectyp == PROPVALUE)) {
      strcpy(bigString,gds2file.record());
      strncpy(string512,bigString,512);
      inProperty=0;
    }
    else if (rectyp == XY) {
      length = gds2file.length();
      if ((length > 65524) || (length < 0)) // 0xffff - 4 for header / 8 = 8191 full 8 byte pairs -- 0=>overflow
	{
	  sprintf(msg, "unsupport XY length (%d - more than 8191 points) found in gds2 file.",length); logError(msg);
	  exit(1);
	}
      nXY = 0;
      for(i=0; i<length; i+=8) {
	if (i == MAXPAIRSXY)
	  {
	    sprintf(msg, "element has > %d coordinates. GDT output lines xy() list is truncated.", MAXPAIRSXY); logError(msg);
	  }
	xcoord = gds2file.getI32(i);
	ycoord = gds2file.getI32(i+4);
	xyArray[nXY++] = xcoord;
	xyArray[nXY++] = ycoord;
      }
    }
    else if (rectyp == LAYER) {
      layer = gds2file.getI16();
      dataType = 0;
      textType = 0;
    }
    else if (rectyp == WIDTH) {
      width = gds2file.getI32();
      if (width != 0) {
	//sprintf(wstring,"%0.5f",((double)width * userUnits) + epsilon);
      }
    }
    else if (rectyp == DATATYPE) {
      dataType = gds2file.getI16();
    }
    else if (rectyp == TEXTTYPE) {
      textType = gds2file.getI16();
    }
    else if (rectyp == ANGLE) {}
    else if (rectyp == MAG) {}
    else if (rectyp == BGNEXTN) {}
    else if (rectyp == ENDEXTN) {}
    else if (rectyp == PROPATTR) {
      inProperty=1;
    }
    else if (rectyp == NODE) {}
    else if (rectyp == NODETYPE) {}
    else if (rectyp == BOX) {}
    else if (rectyp == BOXTYPE) {}
  }  // end of gds read loop
  
  if (!foundTopCell) {
    sprintf(msg, "Cell \"%s\" not found", cellname); logError(msg);
  }
  
  
  struct textRec *t;
  struct geomRec *g;
  int ii=0;
  char uStr[32];
  //printf("DBG: readGds return  intGdsFile = %s\n", intGdsFile);
  return gds;
  
}  // end readGds



void fmtCoord(long iVal, char *fVal) {

  if (iVal < 0) {
    sprintf(fVal,"%0.*f",precision,(iVal * userUnits) - epsilon);
  }
  else {
    sprintf(fVal,"%0.*f",precision,(iVal * userUnits) + epsilon);
  }
}


// ****************************************************************************
// * print_help()
// ****************************************************************************
void print_help()
{
  char bfr[2048], helpFile[1024], line[1024];
  FILE *help;


  strcpy(bfr, thisProgram);
  strcpy(helpFile,dirname(bfr));
  strcat(helpFile, "/README");
  help = fopen(helpFile, "r");
  if (help == NULL) {
    sprintf(msg, "Cannot open %s for read.", helpFile); logError(msg);
    perror(NULL);
    return;
  }
  printf("Help file:  %s\n\n", helpFile);
  while ( fgets(line,1023,help) != NULL ) {fputs(line, stdout);}
  fclose(help);
  return;
}


void * myMalloc(size_t size) {
  static char *curLoc=NULL;   //  Pointer to current location in allocated memory
  static int remaining=0;   //  Remaining size in buffer
  static char *bfr=NULL;
  void *retVal;
  
  if (remaining < size) {
    //  Need to allocate more space
    //    printf("Info:  Malloc\n");
    bfr = (char *) malloc(MEMBLOCKSIZE);
    if (bfr == NULL) {
      fprintf(stderr, "malloc failed\n");
      exit(1);
    }
    curLoc = bfr;  // BOZO:  Check for contiguous space allocation
    remaining = MEMBLOCKSIZE;
  }

  retVal = (void *) curLoc;
  curLoc += size;
  remaining -= size;
  return(retVal);
}

int getLabelType(char *inString) {
  char first;
  first = inString[0];
  
  // Not attempting to filter voltage markers.  Texts are either IPtags or assumed to be names.
  
  //  if (isalpha(first) || (first == '_')) {
  //    return(TEXT_NAME);
  //  }
  //  
  //  if (isdigit(first) || (first == '.')) {
  //    return(TEXT_VMARKER);
  //  }
  
  if ((first == '&')) {
    return(TEXT_IPTAG);
  }
  return(TEXT_NAME);
  
}

//double polygonArea(long *coordArray, int nCoords) {
//  // Calculates the area of a polygon
//  //  Algorithm for getting area measurement from http://www.mathopenref.com/coordpolygonarea.html
//
//  // This requires a closed polygon, as gds boundary objects do (first/last coords are the same)
//
//  double area = 0.0;
//  int i;
//  long *cp;
//  double x1, x2, y1, y2;
//  
//  cp = coordArray;
//  for (i=0; (i<(nCoords-2)); i+=2)
//    {
//      x1 = ((double) *cp)*userUnits;
//      y1 = ((double) *(cp+1))*userUnits;
//      x2 = ((double) *(cp+2))*userUnits;
//      y2 = ((double) *(cp+3))*userUnits;
//      area += (x1*y2) - (y1*x2);
//      cp += 2;
//    }
//    area = fabs(area/2);
//    return area;
//}

// gdsStream.C
// Copyright 1995-2014 by Ken Schumack (Schumack@cpan.org)
// STREAM stuff
// @(#) $Id: gdsStream.C 95 2014-12-08 17:16:36Z schumack $
//#include <string.h>


static const char* gdsStream_Cwhat = "@(#) $Id: gdsStream.C 95 2014-12-08 17:16:36Z schumack $ $Revision: 95 $ $Date: 2014-12-08 11:16:36 -0600 (Mon, 08 Dec 2014) $";

GDSFILE::GDSFILE(char* fileName, int readOrWrite)
{
    int   i,j;
    char* tmpName;

    // remake FileName if found with one of these std extensions ".gds2, .gdsii, .sf, .gds"
    //tmpName = new char[2048];
    //    mystrncpy(tmpName, fileName, 2048);
    tmpName = strsto(fileName);
    if (! strcmp(fileName,""))
    {
        Fd = fileno(stdin);
        //setbuf(stdin, NULL);
        //setbuf(stdin, Buffer);
    }
    else
    {
        Fd = open(tmpName, O_RDONLY, 0777);
    }

    if (Fd == -1)
    {
        strcpy(tmpName, fileName);
        strcat(tmpName, ".gds2");
        Fd = open(tmpName, O_RDONLY, 0777);
    }

    if (Fd == -1)
    {
        strcpy(tmpName, fileName);
        strcat(tmpName, ".gdsii");
        Fd = open(tmpName, O_RDONLY, 0777);
    }

    if (Fd == -1)
    {
        strcpy(tmpName, fileName);
        strcat(tmpName, ".sf");
        Fd = open(tmpName, O_RDONLY, 0777);
    }

    if (Fd == -1)
    {
        strcpy(tmpName, fileName);
        strcat(tmpName, ".gds");
        Fd = open(tmpName, O_RDONLY, 0777);
    }

    //FileName = new char[1024];
    //mystrncpy(FileName, fileName, 1024);
    FileName = strsto(fileName);
    // let the opstrm handle the error if needed

    
    if (Fd != fileno(stdin)) close(Fd);
    
    Eof      = FALSE;
    EndOfLib = FALSE;
    Writtn   = readOrWrite;
    Ptr      = 0;
    for (i=0; i<NUMGDSLAYERS; i++)
    {
        Tlayers[i] = Glayers[i] = FALSE;
        for (j=0; j<NUMGDSLAYERS; j++)
        {
            LayerDataTypes[i][j] = LayerTextTypes[i][j] = FALSE;
        }
    }
    opstrm();
}


// OPSTRM - opens STREAM file for read/write
void GDSFILE::opstrm()
{
  if (Writtn == WRITE)
    {
      if (! strcmp(FileName,""))
        {
	  Fd = fileno(stdout);
#ifdef DEBUG
	  setbuf(stdout, NULL);
#endif
        }
      else
        {
	  Fd = creat(FileName, 0777);
	  if(Fd == -1)
            {
	      printf( "ERROR ***** Unable to create file \"%s\". Exiting...\n", FileName);
	      exit(1);
            }
        }
      Ptr = 0;
    }
  else
    {
      if (! strcmp(FileName,""))
        {
	  Fd = fileno(stdin);
	  setbuf(stdin, NULL);
	  //Fd = dup2(fileno(stdin),9);
        }
      else
        {
	  Fd = open(FileName, O_RDONLY, 0777);
	  if(Fd == -1)
            {
	      printf("ERROR ***** Unable to read file \"%s\". Exiting...",FileName);
	      exit(1);
            }
        }
      Ptr = 204800;
    }
  
}


// RDSTRM - reads next record from STREAM file
int GDSFILE::rdstrm()
{
    int     remain,         // remaining size of tape block
            amount_read,
            amount_read_total = 0;

    Length = 0;
    while (Length == 0)
    {
        if (Ptr > 204799)
        {
            if ((amount_read = read(Fd, Buffer, 204800)) <= 0)
            {
                Eof = TRUE;
                if (amount_read < 0)
                {
                    fprintf(stderr,"ERROR **** problem reading Fd:%d\n",Fd);

                }
                return 0;
            }
            amount_read_total += amount_read;
            Ptr = 0;
        }
        Length = (int)((unsigned short)((Buffer[Ptr]) << 8) | ((unsigned short)(Buffer[Ptr+1]) & 0xff));
        Ptr += 2;
    }

    if (Ptr > 204799)
    {
        if ((amount_read = read(Fd, Buffer, 204800)) <= 0)
        {
            Eof = TRUE;
            if (amount_read < 0)
            {
                fprintf(stderr,"ERROR **** problem reading Fd:%d\n",Fd);

            }
            return 0;
        }
        amount_read_total += amount_read;
        Ptr = 0;
    }
    Rectyp = (int)Buffer[Ptr];
    Dattyp = (int)Buffer[Ptr + 1];
    if (Rectyp==ENDLIB)
    {
        EndOfLib = TRUE;
        Eof = TRUE;
    }
    Ptr += 2;
    Length -= 4;
    if(Length >= 0)
    {
        remain = 204800 - Ptr;
        if(remain <= Length)
        {
            copy(&Buffer[Ptr], Record, remain);
            if ((amount_read = read(Fd, Buffer, 204800)) <= 0)
            {
                Eof = TRUE;
                if (amount_read < 0)
                {
                    fprintf(stderr,"ERROR **** problem reading Fd:%d\n",Fd);

                }
                return 0;
            }
            amount_read_total += amount_read;
            Ptr = 0;
        }
        if(remain < Length)
        {
            copy(Buffer, &Record[remain], (Length - remain));
            Ptr = Length - remain;
        }
        if(remain > Length)
        {
            copy(&Buffer[Ptr], Record, Length);
            Ptr += Length;
        }
    }
    Record[Length] = 0;
    return amount_read_total;
}


// CPSTRM -
void GDSFILE::cpstrm(GDSFILE* gds2file)
{
    wrstrm(gds2file->record(), gds2file);
}


// CPEND -
void GDSFILE::cpend(GDSFILE* gds2file)
{
    int errorCnt = 0;

    for(int i = Ptr; i < 204800; i++) Buffer[i] = gds2file->Buffer[i];
    if (write(Fd, Buffer, 204800) < 0) errorCnt++;
    if (Fd != fileno(stdout)) close(Fd);
}


// WRSTRM - writes private Record to STREAM file
void GDSFILE::wrstrm()
{
    int     remain;   // remaining size of "tape" block
    int     len;      // length of data + rectyp + dattyp
    int     i;
    int     errorCnt = 0;

    len = Length + 4;
    Buffer[Ptr] = (char)((len >> 8) & 0xff);

    if((len & 0x80) == 0) Buffer[Ptr+1] = (char)(len & 0xff);
    else                  Buffer[Ptr+1] = (char)(len & 0xff) | 0x80;

    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    Buffer[Ptr]     = (char)Rectyp;
    Buffer[Ptr + 1] = (char)Dattyp;
    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    if(Length >= 0)
    {
        remain = 204800 - Ptr;
        if(remain <= Length)
        {
            copy(Record, &Buffer[Ptr], remain);
            if (write(Fd, Buffer, 204800) < 0) errorCnt++;
            Ptr = 0;
            for(i = 0; i < 204800; Buffer[i] = 0, i++);
        }

        if(remain < Length)
        {
            copy(&Record[remain], Buffer, (Length - remain));
            Ptr = Length - remain;
        }

        if(remain > Length)
        {
            copy(Record, &Buffer[Ptr], Length);
            Ptr += Length;
        }
    }
}


// WRSTRM - writes external Record to STREAM file using Length,Rectyp, and Dattyp of existing record
void GDSFILE::wrstrm(char record[204800], GDSFILE* gds2file)
{
    int remain;   // remaining size of "tape" block
    int len;      // length of data + rectyp + dattyp
    int i;
    int errorCnt = 0;

    Length = gds2file -> Length;
    Rectyp = gds2file -> Rectyp;
    Dattyp = gds2file -> Dattyp;

    len = Length + 4;
    Buffer[Ptr] = (char)((len >> 8) & 0xff);

    if((len & 0x80) == 0) Buffer[Ptr+1] = (char)(len & 0xff);
    else                  Buffer[Ptr+1] = (char)(len & 0xff) | 0x80;

    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    Buffer[Ptr]     = (char)Rectyp;
    Buffer[Ptr + 1] = (char)Dattyp;
    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    if(Length >= 0)
    {
        remain = 204800 - Ptr;
        if(remain <= Length)
        {
            copy(record, &Buffer[Ptr], remain);
            if (write(Fd, Buffer, 204800) < 0) errorCnt++;
            Ptr = 0;
            for(i = 0; i < 204800; Buffer[i] = 0, i++);
        }

        if(remain < Length)
        {
            copy(&record[remain], Buffer, (Length - remain));
            Ptr = Length - remain;
        }

        if(remain > Length)
        {
            copy(record, &Buffer[Ptr], Length);
            Ptr += Length;
        }
    }
}


// WRSTRM - writes external Record to STREAM file
void GDSFILE::wrstrm(char record[204800], int rectyp, int dattyp, int length)
{
    int remain;   // remaining size of "tape" block
    int len;      // length of data + rectyp + dattyp
    int i;
    int errorCnt = 0;

    len = length + 4;
    Buffer[Ptr] = (char)((len >> 8) & 0xff);

    if((len & 0x80) == 0) Buffer[Ptr+1] = (char)(len & 0xff);
    else                  Buffer[Ptr+1] = (char)(len & 0xff) | 0x80;

    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    Buffer[Ptr]     = (char)rectyp;
    Buffer[Ptr + 1] = (char)dattyp;
    Ptr += 2;
    if(Ptr > 204799)
    {
        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
        Ptr = 0;
    }

    if(length >= 0)
    {
        remain = 204800 - Ptr;
        if(remain <= length)
        {
            copy(record, &Buffer[Ptr], remain);
            if (write(Fd, Buffer, 204800) < 0) errorCnt++;
            Ptr = 0;
            for(i = 0; i < 204800; Buffer[i] = 0, i++);
        }

        if(remain < length)
        {
            copy(&record[remain], Buffer, (length - remain));
            Ptr = length - remain;
        }

        if(remain > length)
        {
            copy(record, &Buffer[Ptr], length);
            Ptr += length;
        }
    }
}


// CLSTRM - closes STREAM file
void GDSFILE::clstrm()
{
    int i;              // loop counter for zero fill
    int errorCnt = 0;

    if(Writtn == WRITE) // pad w/ zeros
    {
        for(i = Ptr; i < 204800; i++) Buffer[i] = 0;

        if (write(Fd, Buffer, 204800) < 0) errorCnt++;
    }

    if (Fd != fileno(stdout)) close(Fd);
}


// writes an ENDEL to stream file
void GDSFILE::endEl()
{
    Length = 0;
    Rectyp = ENDEL;
    Dattyp = NO_DATA;
    wrstrm();
}


// WRITES A GDSII ENDLIB RECORD
void GDSFILE::endLib()
{
    // WRITE ENDLIB
    Length = 0;
    Rectyp = ENDLIB;
    Dattyp = NO_DATA;
    wrstrm();
}


// WRITES A GDSII ENDSTR RECORD
void GDSFILE::endStr()
{
    // WRITE ENDSTR
    Length = 0;
    Rectyp = ENDSTR;
    Dattyp = NO_DATA;
    wrstrm();
}


// GET_DBL - returns 64 bit real from GDS STREAM data representation
double GDSFILE::getDbl()
{
    int     i,
            byte,
            negative,
            expon;
    double  mant,
            dbl;

    byte = (int)(*Record & 0xff);
    if (byte > 127)
    {
        negative = TRUE;
        expon = byte - 192;
    }
    else
    {
        negative = FALSE;
        expon = byte - 64;
    }

    mant = 0.0;
    for (i = 1; i <= 7; i++)
    {
        byte = (int)(*(Record + i) & 0xff);
        mant = mant + ((double)byte) / pow((double)256, (double)i);
    }
    dbl = mant * pow((double)16, (double)expon);
    if (negative) dbl = -dbl;

    return dbl;
}


// GET_DBL - returns 64 bit real from GDS STREAM data representation
double GDSFILE::getDbl(int offset)
{
    int     i,
            byte,
            negative,
            expon;
    double  mant,
            dbl;

    byte = (int)(*(Record + offset) & 0xff);
    if (byte > 127)
    {
        negative = TRUE;
        expon = byte - 192;
    }
    else
    {
        negative = FALSE;
        expon = byte - 64;
    }

    mant = 0.0;
    for (i = 1; i <= 7; i++)
    {
        byte = (int)(*(Record + offset + i) & 0xff);
        mant = mant + ((double)byte) / pow((double)256, (double)i);
    }
    dbl = mant * pow((double)16, (double)expon);
    if (negative) dbl = -dbl;

    return dbl;
}


// GET_I16 - returns 16 bit integer from GDS STREAM data representation
int GDSFILE::getI16(int offset)
{
    int     negative;
    int     byte;
    int     int16;

    byte = (int)(*(Record + offset) & 0xff);

    if(byte > 127) negative = TRUE;
    else           negative = FALSE;

    int16 = byte;
    byte = (int)(*(Record + offset + 1) & 0xff);
    int16 = int16 * 256 + byte;

    if (negative) int16 = int16 - 65536;

    return(int16);
}


// GET_I16 - returns 16 bit integer from GDS STREAM data representation
int GDSFILE::getI16()
{
    int     negative;
    int     byte;
    int     int16;

    byte = (int)(*Record & 0xff);

    if(byte > 127) negative = TRUE;
    else           negative = FALSE;

    int16 = byte;
    byte = (int)(*(Record + 1) & 0xff);
    int16 = int16 * 256 + byte;

    if (negative) int16 = int16 - 65536;

    return(int16);
}


// GET_I32 - returns 32 bit integer from GDS STREAM data representation
int GDSFILE::getI32()
{
    int     i,
            negative,
            byte,
            int32;

    byte = (int)(*Record & 0xff);
    if(byte > 127)
    {
        byte = byte - 255;
        negative = TRUE;
    }
    else  negative = FALSE;

    int32 = byte;
    for(i = 1; i <= 3; i++)
        {
        byte = (int)(*(Record + i) & 0xff);
        if(negative) byte = byte - 255;
        int32 = int32 * 256 + byte;
    }

    if (negative) int32 = int32 - 1;

    return int32;
}


// GET_I32 - returns 32 bit integer from GDS STREAM data representation
int GDSFILE::getI32(int offset)
{
    int     i,
            negative,
            byte,
            int32;

    byte = (int)(*(Record + offset) & 0xff);
    if(byte > 127)
    {
        byte = byte - 255;
        negative = TRUE;
    }
    else  negative = FALSE;

    int32 = byte;
    for(i = 1; i <= 3; i++)
        {
        byte = (int)(*(Record + offset + i) & 0xff);
        if(negative) byte = byte - 255;
        int32 = int32 * 256 + byte;
    }

    if (negative) int32 = int32 - 1;

    return int32;
}


// 0 || 1 depending on whether we are at EOF
int GDSFILE::eof()
{
    return Eof;
}


// 0 || 1 depending on whether we are at EOF
int GDSFILE::endoflib()
{
    return EndOfLib;
}


// return Length of Record
int GDSFILE::length()
{
    return Length;
}


// set Length of Record
void GDSFILE::length(int len)
{
    if (len < 4)
    {
      printf("ERROR:: Program attempted to set invalid Length\n");
    }
    else Length = len;
}


// return Dattyp of Record
int GDSFILE::dattyp()
{
    return Dattyp;
}


// set Dattyp of Record
void GDSFILE::dattyp(int dattype)
{
    if ((dattype > 6) || (dattype < 0))
    {
      printf("ERROR:: Program attempted to set invalid Dattyp\n");
      Dattyp = NO_DATA;
    }
    else Dattyp = dattype;
}


// return Rectyp of Record
int GDSFILE::rectyp()
{
    return Rectyp;
}


// set Rectyp of Record
void GDSFILE::rectyp(int rectype)
{
    if ((rectype > 59) || (rectype < 0))
    {
      printf("ERROR:: Program attempted to set invalid Rectyp\n");
      Rectyp = HEADER;
    }
    else Rectyp = rectype;
}


// return GDS Record
char* GDSFILE::record()
{
    return Record;
}


// store library name
void GDSFILE::libName(char* name)
{
    LibName = new char[strlen(name) + 1];
    strcpy(LibName, name);
}


// get stored library name
char* GDSFILE::libName()
{
    return LibName;
}


// get stored stream file name
char* GDSFILE::fileName()
{
    return FileName;
}


// use to save the fact that you found a text layer in the gds file
void GDSFILE::foundTextLayer(short layerNum)
{
    if (layerNum < NUMGDSLAYERS)
    {
        Tlayers[layerNum] = TRUE;
    }
    else
    {
      printf( "ERROR **** Found graphics layer %d in structure %s\n",layerNum, CurrentStrName);
    }
}


// use to save the fact that you found a graphics layer in the gds file
void GDSFILE::foundGraphicsLayer(short layerNum)
{
    if (layerNum < NUMGDSLAYERS)
    {
        Glayers[layerNum] = TRUE;
    }
    else
    {
      printf("ERROR **** Found graphics layer %d in structure %s\n",layerNum,CurrentStrName);
    }
}


// use to save the fact that you found a datatype in the gds file
void GDSFILE::foundLayerDatatype(short layerNum, short dataTypeNum)
{
    if ((layerNum < NUMGDSLAYERS) && (dataTypeNum < NUMGDSLAYERS))
    {
        LayerDataTypes[layerNum][dataTypeNum] = TRUE;
    }
    else
    {
      printf("ERROR **** Found graphics layer %d with datatype %d in structure %s\n",layerNum,dataTypeNum,CurrentStrName);
    }
}


// use to save the fact that you found a datatype in the gds file
void GDSFILE::foundLayerTexttype(short layerNum, short textTypeNum)
{
    if ((layerNum < NUMGDSLAYERS) && (textTypeNum < NUMGDSLAYERS))
    {
        LayerTextTypes[layerNum][textTypeNum] = TRUE;
    }
    else
    {
      printf("ERROR **** Found graphics layer %d with texttype %d in structure %s\n", layerNum, textTypeNum, CurrentStrName);
    }
}


// true or false .. does this graphics layer exist in the stream file?
int GDSFILE::gLayer(short layerNum)
{
    if ((layerNum < NUMGDSLAYERS) && Glayers[layerNum]) return TRUE;
    else return FALSE;
}


// true or false .. does this graphicsLayer/dataType exist in the stream file?
int GDSFILE::layerDataType(short layerNum, short dataType)
{
    if ((layerNum < NUMGDSLAYERS) && (dataType < NUMGDSLAYERS) &&
             LayerDataTypes[layerNum][dataType]) return TRUE;
    else return FALSE;
}


// true or false .. does this text layer exist in the stream file?
int GDSFILE::tLayer(short layerNum)
{
    if ((layerNum < NUMGDSLAYERS) && Tlayers[layerNum]) return TRUE;
    else return FALSE;
}


// true or false .. does this textLayer/textType exist in the stream file?
int GDSFILE::layerTextType(short layerNum, short textType)
{
    if ((layerNum < NUMGDSLAYERS) && (textType < NUMGDSLAYERS) &&
             LayerTextTypes[layerNum][textType]) return TRUE;
    else return FALSE;
}


//
void GDSFILE::copy(char src_rec[],    // source record
                   char dst_rec[],    // destination record
                   int  num)          // number of chars for copy
{
    for(int i = 0; i < num; i++)  dst_rec[i] = src_rec[i];
}

/// PUTS AREF IN LIBRARY {like Calma's AREF command}
void GDSFILE::putAref(
         char*  sname,
         unsigned short ref,   // 1 for reflection, 0 for no reflection
         double mag,
         double angle,
         short  col,
         short  row,
         double x1, double y1, double x2, double y2, double x3, double y3, // x1y1:Origin, x2y2:Column, x3y3:Row
         int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING],
         double dbu_uu
)
{
    int index;
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE AREF
    Length = 0;
    Rectyp = AREF;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length] = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE COLROW
    Length = 4;
    Rectyp = COLROW;
    Dattyp = INTEGER_2;
    putI16(col, 0);
    putI16(row, 2);
    wrstrm();

    // WRITE XY
    Length = 24;
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (x1 >= 0.0) { putI32((long int)((x1 + epsilon) * factor), 0); }
    else           { putI32((long int)((x1 - epsilon) * factor), 0); }

    if (y1 >= 0.0) { putI32((long int)((y1 + epsilon) * factor), 4); }
    else           { putI32((long int)((y1 - epsilon) * factor), 4); }

    if (x2 >= 0.0) { putI32((long int)((x2 + epsilon) * factor), 8); }
    else           { putI32((long int)((x2 - epsilon) * factor), 8); }

    if (y2 >= 0.0) { putI32((long int)((y2 + epsilon) * factor), 12); }
    else           { putI32((long int)((y2 - epsilon) * factor), 12); }

    if (x3 >= 0.0) { putI32((long int)((x3 + epsilon) * factor), 16); }
    else           { putI32((long int)((x3 - epsilon) * factor), 16); }

    if (y3 >= 0.0) { putI32((long int)((y3 + epsilon) * factor), 20); }
    else           { putI32((long int)((y3 - epsilon) * factor), 20); }

    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();
}


/// PUTS AREF IN LIBRARY {like Calma's AREF command}
void GDSFILE::putAref(
         char*  sname,
         unsigned short ref,   // 1 for reflection, 0 for no reflection
         double mag,
         double angle,
         short  col,
         short  row,
         double x1, double y1, double x2, double y2, double x3, double y3, // x1y1:Origin, x2y2:Column, x3y3:Row
         double dbu_uu
)
{
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE AREF
    Length = 0;
    Rectyp = AREF;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length] = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE COLROW
    Length = 4;
    Rectyp = COLROW;
    Dattyp = INTEGER_2;
    putI16(col, 0);
    putI16(row, 2);
    wrstrm();

    // WRITE XY
    Length = 24;
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (x1 >= 0.0) { putI32((long int)((x1 + epsilon) * factor), 0); }
    else           { putI32((long int)((x1 - epsilon) * factor), 0); }

    if (y1 >= 0.0) { putI32((long int)((y1 + epsilon) * factor), 4); }
    else           { putI32((long int)((y1 - epsilon) * factor), 4); }

    if (x2 >= 0.0) { putI32((long int)((x2 + epsilon) * factor), 8); }
    else           { putI32((long int)((x2 - epsilon) * factor), 8); }

    if (y2 >= 0.0) { putI32((long int)((y2 + epsilon) * factor), 12); }
    else           { putI32((long int)((y2 - epsilon) * factor), 12); }

    if (x3 >= 0.0) { putI32((long int)((x3 + epsilon) * factor), 16); }
    else           { putI32((long int)((x3 - epsilon) * factor), 16); }

    if (y3 >= 0.0) { putI32((long int)((y3 + epsilon) * factor), 20); }
    else           { putI32((long int)((y3 - epsilon) * factor), 20); }

    wrstrm();

    // WRITE ENDEL
    endEl();
}


/// PUTS AREF IN LIBRARY {like Calma's AREF command}
void GDSFILE::putAref(
         char*  sname,
         unsigned short ref,   // 1 for reflection, 0 for no reflection
         double mag,
         double angle,
         short  col,
         short  row,
         double x1, double y1, double x2, double y2, double x3, double y3 // x1y1:Origin, x2y2:Column, x3y3:Row
)
{
    // WRITE AREF
    Length = 0;
    Rectyp = AREF;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length] = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE COLROW
    Length = 4;
    Rectyp = COLROW;
    Dattyp = INTEGER_2;
    putI16(col, 0);
    putI16(row, 2);
    wrstrm();

    // WRITE XY
    Length = 24;
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (x1 >= 0.0) { putI32((long int)((x1 + G_epsilon) * 1000), 0); }
    else           { putI32((long int)((x1 - G_epsilon) * 1000), 0); }

    if (y1 >= 0.0) { putI32((long int)((y1 + G_epsilon) * 1000), 4); }
    else           { putI32((long int)((y1 - G_epsilon) * 1000), 4); }

    if (x2 >= 0.0) { putI32((long int)((x2 + G_epsilon) * 1000), 8); }
    else           { putI32((long int)((x2 - G_epsilon) * 1000), 8); }

    if (y2 >= 0.0) { putI32((long int)((y2 + G_epsilon) * 1000), 12); }
    else           { putI32((long int)((y2 - G_epsilon) * 1000), 12); }

    if (x3 >= 0.0) { putI32((long int)((x3 + G_epsilon) * 1000), 16); }
    else           { putI32((long int)((x3 - G_epsilon) * 1000), 16); }

    if (y3 >= 0.0) { putI32((long int)((y3 + G_epsilon) * 1000), 20); }
    else           { putI32((long int)((y3 - G_epsilon) * 1000), 20); }

    wrstrm();

    // WRITE ENDEL
    endEl();
}


// PUTDBL - puts 64 bit real in stream output buffer
void GDSFILE::putDbl(double  dbl, int offset)
{
    int     negative;
    double  r;
    int     expon;
    int     i;
    int     byte;

    if(dbl < 0.0)
    {
        negative = TRUE;
        r = -dbl;
    }
    else
    {
        negative = FALSE;
        r = dbl;
    }

    expon = 0;
    while(r >= 1.0)
    {
        expon++;
        r = r / 16.0;
    }

    if (r != 0)
    {
        while(r < 0.0625)
        {
            expon--;
            r = r * 16.0;
        }
    }

    if(negative == 1) expon = 192 + expon;
    else              expon =  64 + expon;

    *(Record + offset) = (char)expon;

    for(i = 1; i <= 7; i++)
    {
        byte = (int)(r*256.0);
        *(Record + offset + i) = (char)byte;
        r = r * 256.0 - (double)byte;
    }
}


// PUTI32 - puts 32 bit integer in stream output buffer
void GDSFILE::putI32(int i32, int offset)
{
    int     negative,
            rem,
            i,
            byte,
            fact;

    if(i32 < 0)
    {
        negative = TRUE;
        rem = -i32 -1;
    }
    else
    {
        negative = FALSE;
        rem = i32;
    }

    fact = 256 * 256 * 256;
    for(i = 3; i >= 0; i--)
    {
        byte = rem / fact;
        rem = rem - byte * fact;
        if(negative == 1) byte = 255 - byte;
        *(Record + offset + 3 - i) = (char)byte;
        fact = fact / 256;
    }
}


// PUTI16 - puts 16 bit integer in stream output buffer
void GDSFILE::putI16(unsigned short i16, int offset)
{
    unsigned short     rem;

    rem = i16;
    *(Record + offset)     = (char)(rem / 256);
    *(Record + offset + 1) = (char)(rem % 256);
}

// INITIALIZES LIBRARY HEADER, BGNLIB, LIBNAME, UNITS
//    {for Calma compabability end the library name with ".DB"}
void GDSFILE::initLib(char *library, double dbu_uu, double dbu_m,
    int myear, int mmon, int mmday, int mhour, int mmin, int msec,
    int ayear, int amon, int amday, int ahour, int amin, int asec,
    int version)
{
    // WRITE HEADER
    Length = 2;
    Rectyp = HEADER;
    Dattyp = INTEGER_2;
    putI16(version, 0);    // writing release 3 type stuff
    wrstrm();

    // WRITE BGNLIB
    Length = 24;
    Rectyp = BGNLIB;
    Dattyp = INTEGER_2;
    if (myear > 1900) myear -= 1900;
    putI16(myear, 0);   // modification time
    putI16(mmon,  2);
    putI16(mmday, 4);
    putI16(mhour, 6);
    putI16(mmin,  8);
    putI16(msec, 10);
    if (ayear > 1900) ayear -= 1900;
    putI16(ayear, 12);  // last access time
    putI16(amon,  14);
    putI16(amday, 16);
    putI16(ahour, 18);
    putI16(amin,  20);
    putI16(asec,  22);
    wrstrm();

    // WRITE LIBNAME
    strcpy(Record, library);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = LIBNAME;
    Dattyp = ACSII_STRING;
    wrstrm();
    libName(library);

    // WRITE UNITS
    Length = 16;
    Rectyp = UNITS;
    Dattyp = REAL_8;
    putDbl(dbu_uu, 0);     // Calma default is 1.0e-3
    putDbl(dbu_m,  8);     // Calma default is 1.0e-9
    wrstrm();
}


// INITIALIZES LIBRARY HEADER, BGNLIB, LIBNAME, UNITS
//    {for Calma compabability end the library name with ".DB"}
void GDSFILE::initLib(char *library, double dbu_uu, double dbu_m,
    int myear, int mmon, int mmday, int mhour, int mmin, int msec,
    int ayear, int amon, int amday, int ahour, int amin, int asec)
{
    GDSFILE::initLib(library,dbu_uu,dbu_m,myear,mmon,mmday,mhour,mmin,msec,ayear,amon,amday,ahour,amin,asec,3);
}


// INITIALIZES LIBRARY HEADER, BGNLIB, LIBNAME, UNITS
//    {for Calma compabability end the library name with ".DB"}
void GDSFILE::initLib(char *library, double dbu_uu, double dbu_m)
{
    struct  tm   *ts;
    time_t       time_val;

    // WRITE HEADER
    Length = 2;
    Rectyp = HEADER;
    Dattyp = INTEGER_2;
    putI16(3, 0);    // writing release 3 type stuff
    wrstrm();

    // WRITE BGNLIB
    Length = 24;
    Rectyp = BGNLIB;
    Dattyp = INTEGER_2;
    time(&time_val);
    ts = localtime(&time_val);
    putI16(ts->tm_year,    0);   // modification time
    putI16(ts->tm_mon + 1, 2);
    putI16(ts->tm_mday,    4);
    putI16(ts->tm_hour,    6);
    putI16(ts->tm_min,     8);
    putI16(ts->tm_sec,     10);
    putI16(ts->tm_year,    12);  // last access time
    putI16(ts->tm_mon + 1, 14);
    putI16(ts->tm_mday,    16);
    putI16(ts->tm_hour,    18);
    putI16(ts->tm_min,     20);
    putI16(ts->tm_sec,     22);
    wrstrm();

    // WRITE LIBNAME
    strcpy(Record, library);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = LIBNAME;
    Dattyp = ACSII_STRING;
    wrstrm();
    libName(library);

    // WRITE UNITS
    Length = 16;
    Rectyp = UNITS;
    Dattyp = REAL_8;
    putDbl(dbu_uu, 0);     // Calma default is 1.0e-3
    putDbl(dbu_m,  8);     // Calma default is 1.0e-9
    wrstrm();
}


// INITIALIZES LIBRARY HEADER, BGNLIB, LIBNAME, UNITS
//    {for Calma compabability end the library name with ".DB"}
void GDSFILE::initLib(char *library)
{
    struct  tm   *ts;
    time_t       time_val;

    // WRITE HEADER
    Length = 2;
    Rectyp = HEADER;
    Dattyp = INTEGER_2;
    putI16(3, 0);    // writing release 3 type stuff
    wrstrm();

    // WRITE BGNLIB
    Length = 24;
    Rectyp = BGNLIB;
    Dattyp = INTEGER_2;
    time(&time_val);
    ts = localtime(&time_val);
    putI16(ts->tm_year,    0);   // modification time
    putI16(ts->tm_mon + 1, 2);
    putI16(ts->tm_mday,    4);
    putI16(ts->tm_hour,    6);
    putI16(ts->tm_min,     8);
    putI16(ts->tm_sec,     10);
    putI16(ts->tm_year,    12);  // last access time
    putI16(ts->tm_mon + 1, 14);
    putI16(ts->tm_mday,    16);
    putI16(ts->tm_hour,    18);
    putI16(ts->tm_min,     20);
    putI16(ts->tm_sec,     22);
    wrstrm();

    // WRITE LIBNAME
    strcpy(Record, library);
    Length = strlen(Record);
    if (Length%2)
    {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = LIBNAME;
    Dattyp = ACSII_STRING;
    wrstrm();
    libName(library);

    // WRITE UNITS
    Length = 16;
    Rectyp = UNITS;
    Dattyp = REAL_8;
    putDbl(1.0e-3, 0);     // Calma default is 1.0e-3
    putDbl(1.0e-9, 8);     // Calma default is 1.0e-9
    wrstrm();
}


// PUTS A RECTANGULAR BOUNDARY ON A SPECIFIED LAYER {like calma's RT command}
void GDSFILE::putRt(int    layer,
       int    datatyp,
       double minX, double minY,
       double maxX, double maxY,
       double dbu_uu)
{
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = 40;                    // 10 4 byte records
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (minX >= 0.0) { putI32((long int)((minX + epsilon) * factor),  0); }   // lower left corner
    else             { putI32((long int)((minX - epsilon) * factor),  0); }   // lower left corner

    if (minY >= 0.0) { putI32((long int)((minY + epsilon) * factor),  4); }
    else             { putI32((long int)((minY - epsilon) * factor),  4); }

    if (minX >= 0.0) { putI32((long int)((minX + epsilon) * factor),  8); }   // upper left corner
    else             { putI32((long int)((minX - epsilon) * factor),  8); }   // upper left corner

    if (maxY >= 0.0) { putI32((long int)((maxY + epsilon) * factor), 12); }
    else             { putI32((long int)((maxY - epsilon) * factor), 12); }

    if (maxX >= 0.0) { putI32((long int)((maxX + epsilon) * factor), 16); }   // upper right corner
    else             { putI32((long int)((maxX - epsilon) * factor), 16); }   // upper right corner

    if (maxY >= 0.0) { putI32((long int)((maxY + epsilon) * factor), 20); }
    else             { putI32((long int)((maxY - epsilon) * factor), 20); }

    if (maxX >= 0.0) { putI32((long int)((maxX + epsilon) * factor), 24); }   // lower right corner
    else             { putI32((long int)((maxX - epsilon) * factor), 24); }   // lower right corner

    if (minY >= 0.0) { putI32((long int)((minY + epsilon) * factor), 28); }
    else             { putI32((long int)((minY - epsilon) * factor), 28); }

    if (minX >= 0.0) { putI32((long int)((minX + epsilon) * factor), 32); }   // lower left corner again
    else             { putI32((long int)((minX - epsilon) * factor), 32); }   // lower left corner again

    if (minY >= 0.0) { putI32((long int)((minY + epsilon) * factor), 36); }
    else             { putI32((long int)((minY - epsilon) * factor), 36); }

    wrstrm();

    // WRITE ENDEL
    endEl();
}


// PUTS A RECTANGULAR BOUNDARY ON A SPECIFIED LAYER {like calma's RT command}
void GDSFILE::putRt(int    layer,
       int    datatyp,
       double minX, double minY,
       double maxX, double maxY)
{
    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = 40;                    // 10 4 byte records
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (minX >= 0.0) { putI32((long int)((minX + G_epsilon) * 1000),  0); }   // lower left corner
    else             { putI32((long int)((minX - G_epsilon) * 1000),  0); }   // lower left corner

    if (minY >= 0.0) { putI32((long int)((minY + G_epsilon) * 1000),  4); }
    else             { putI32((long int)((minY - G_epsilon) * 1000),  4); }

    if (minX >= 0.0) { putI32((long int)((minX + G_epsilon) * 1000),  8); }   // upper left corner
    else             { putI32((long int)((minX - G_epsilon) * 1000),  8); }   // upper left corner

    if (maxY >= 0.0) { putI32((long int)((maxY + G_epsilon) * 1000), 12); }
    else             { putI32((long int)((maxY - G_epsilon) * 1000), 12); }

    if (maxX >= 0.0) { putI32((long int)((maxX + G_epsilon) * 1000), 16); }   // upper right corner
    else             { putI32((long int)((maxX - G_epsilon) * 1000), 16); }   // upper right corner

    if (maxY >= 0.0) { putI32((long int)((maxY + G_epsilon) * 1000), 20); }
    else             { putI32((long int)((maxY - G_epsilon) * 1000), 20); }

    if (maxX >= 0.0) { putI32((long int)((maxX + G_epsilon) * 1000), 24); }   // lower right corner
    else             { putI32((long int)((maxX - G_epsilon) * 1000), 24); }   // lower right corner

    if (minY >= 0.0) { putI32((long int)((minY + G_epsilon) * 1000), 28); }
    else             { putI32((long int)((minY - G_epsilon) * 1000), 28); }

    if (minX >= 0.0) { putI32((long int)((minX + G_epsilon) * 1000), 32); }   // lower left corner again
    else             { putI32((long int)((minX - G_epsilon) * 1000), 32); }   // lower left corner again

    if (minY >= 0.0) { putI32((long int)((minY + G_epsilon) * 1000), 36); }
    else             { putI32((long int)((minY - G_epsilon) * 1000), 36); }

    // WRITE ENDEL
    endEl();
}

// PUTS SREF IN LIBRARY {like Calma's SREF command}
void GDSFILE::putSref( char*  sname,
          unsigned short ref,  // 0 or 1
          double mag,
          double angle,
          double x_coord,
          double y_coord,
          int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING],
          double dbu_uu)
{
    int index;
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE SREF
    Length = 0;
    Rectyp = SREF;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (x_coord >= 0.0) { putI32((long int)((x_coord + epsilon) * factor), 0); }
    else                { putI32((long int)((x_coord - epsilon) * factor), 0); }
    if (y_coord >= 0.0) { putI32((long int)((y_coord + epsilon) * factor), 4); }
    else                { putI32((long int)((y_coord - epsilon) * factor), 4); }
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();
}

// PUTS SREF IN LIBRARY {like Calma's SREF command}
void GDSFILE::putSref( char*  sname,
          unsigned short ref,  // 0 or 1
          double mag,
          double angle,
          double x_coord,
          double y_coord,
          double dbu_uu)
{
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE SREF
    Length = 0;
    Rectyp = SREF;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;

    if (x_coord >= 0.0) { putI32((long int)((x_coord + epsilon) * factor), 0); }
    else                { putI32((long int)((x_coord - epsilon) * factor), 0); }
    if (y_coord >= 0.0) { putI32((long int)((y_coord + epsilon) * factor), 4); }
    else                { putI32((long int)((y_coord - epsilon) * factor), 4); }
    wrstrm();

    // WRITE ENDEL
    endEl();
}


// PUTS SREF IN LIBRARY {like Calma's SREF command}
void GDSFILE::putSref( char*  sname,
          unsigned short ref,  // 0 or 1
          double mag,
          double angle,
          double x_coord,
          double y_coord)
{
    // WRITE SREF
    Length = 0;
    Rectyp = SREF;
    Dattyp = NO_DATA;
    wrstrm();
    // WRITE SNAME
    strcpy(Record, sname);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = SNAME;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x_coord >= 0.0) { putI32((long int)((x_coord + G_epsilon) * 1000), 0); }
    else                { putI32((long int)((x_coord - G_epsilon) * 1000), 0); }
    if (y_coord >= 0.0) { putI32((long int)((y_coord + G_epsilon) * 1000), 4); }
    else                { putI32((long int)((y_coord - G_epsilon) * 1000), 4); }
    wrstrm();

    // WRITE ENDEL
    endEl();
}


// INITIALIZE STRUCTURE (like Calma's BSTRUCT)
void GDSFILE::beginStr(char *str_name,
    int myear, int mmon, int mmday, int mhour, int mmin, int msec,
    int ayear, int amon, int amday, int ahour, int amin, int asec)
{
    time_t       time_val;
    struct  tm   *ts;

    // WRITE BGNSTR
    Length = 24;
    Rectyp = BGNSTR;
    Dattyp = INTEGER_2;
    time(&time_val);
    ts = localtime(&time_val);
    putI16(myear,0);   // modification time
    putI16(mmon, 2);
    putI16(mmday,4);
    putI16(mhour,6);
    putI16(mmin, 8);
    putI16(msec, 10);
    putI16(ayear,12);   // last access time
    putI16(amon, 14);
    putI16(amday,16);
    putI16(ahour,18);
    putI16(amin, 20);
    putI16(asec, 22);
    wrstrm();

    // WRITE STRNAME
    strcpy(Record, str_name);
    Length =  strlen(Record);
    if (Length%2)
    {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRNAME;
    Dattyp = ACSII_STRING;
    wrstrm();
}


// INITIALIZE STRUCTURE (like Calma's BSTRUCT)
void GDSFILE::beginStr(char *str_name)
{
    time_t       time_val;
    struct  tm   *ts;

    // WRITE BGNSTR
    Length = 24;
    Rectyp = BGNSTR;
    Dattyp = INTEGER_2;
    time(&time_val);
    ts = localtime(&time_val);
    putI16(ts->tm_year,     0);   // modification time
    putI16(ts->tm_mon + 1,  2);
    putI16(ts->tm_mday,     4);
    putI16(ts->tm_hour,     6);
    putI16(ts->tm_min,      8);
    putI16(ts->tm_sec,     10);
    putI16(ts->tm_year,    12);   // last access time
    putI16(ts->tm_mon + 1, 14);
    putI16(ts->tm_mday,    16);
    putI16(ts->tm_hour,    18);
    putI16(ts->tm_min,     20);
    putI16(ts->tm_sec,     22);
    wrstrm();

    // WRITE STRNAME
    strcpy(Record, str_name);
    Length =  strlen(Record);
    if (Length%2)
    {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRNAME;
    Dattyp = ACSII_STRING;
    wrstrm();
}


//*********** putText *********************
//  PUTS A TEXT RECORD ON SPECIFIED LAYER *
//  layer must be >=0 && <=255            *
//*****************************************
void GDSFILE::putText(unsigned short layer,
                      unsigned short ref,  // 1 or 0
                      double         mag,
                      double         angle,
                      double x, double y,
                      char*          txt,
                      int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING],
                      double dbu_uu)
{
    int      index;
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;
    unsigned short int tt = 0;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(tt, 0);
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + epsilon) * factor), 0); }
    else          { putI32((long int)((x - epsilon) * factor), 0); }
    if (y >= 0.0) { putI32((long int)((y + epsilon) * factor), 4); }
    else          { putI32((long int)((y - epsilon) * factor), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();
}


//*********** putText *********************
//* PUTS A TEXT RECORD ON SPECIFIED LAYER *
//* layer must be >=0 && <=255            *
//*****************************************
void GDSFILE::putText(unsigned short layer,
                      unsigned short ref,  // 1 or 0
                      double         mag,
                      double         angle,
                      double x, double y,
                      char*          txt,
                      double dbu_uu)
{
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;
    unsigned short int tt = 0;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(tt, 0);
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + epsilon) * factor), 0); }
    else          { putI32((long int)((x - epsilon) * factor), 0); }
    if (y >= 0.0) { putI32((long int)((y + epsilon) * factor), 4); }
    else          { putI32((long int)((y - epsilon) * factor), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE ENDEL
    endEl();
}


//*********** putText *********************
//* PUTS A TEXT RECORD ON SPECIFIED LAYER *
//* layer must be >=0 && <=255            *
//*****************************************
void GDSFILE::putText(unsigned short layer,
                      unsigned short ref,  // 1 or 0
                      double         mag,
                      double         angle,
                      double x, double y,
                      char*          txt)
{
    unsigned short int tt = 0;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(tt, 0);
    wrstrm();

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    Length = 8;
    Rectyp = MAG;
    Dattyp = REAL_8;
    putDbl(mag, 0);
    wrstrm();

    // WRITE ANGLE
    Length = 8;
    Rectyp = ANGLE;
    Dattyp = REAL_8;
    putDbl(angle, 0);
    wrstrm();

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + G_epsilon) * 1000), 0); }
    else          { putI32((long int)((x - G_epsilon) * 1000), 0); }
    if (y >= 0.0) { putI32((long int)((y + G_epsilon) * 1000), 4); }
    else          { putI32((long int)((y - G_epsilon) * 1000), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE ENDEL
    endEl();
}


//*********** putText *********************
//* PUTS A TEXT RECORD ON SPECIFIED LAYER *
//* layer must be >=0 && <=64K            *
//*****************************************
//#  <text>::=          TEXT [ELFLAGS] [PLEX] LAYER <textbody>                   #
//#                                                                              #
//#  <textbody>::=      TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY #
//#                     STRING                                                   #
//#                                                                              #
//#  <strans>::=        STRANS [MAG] [ANGLE]                                     #
void GDSFILE::putText(unsigned short layer,
                      unsigned short textType,
                      unsigned short fontType,
                      char*          textJust,
                      unsigned short pathType,
                      double         width,
                      unsigned short ref,
                      double         mag,
                      double         angle,
                      double         x,
                      double         y,
                      char*          txt,
                      int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING],
                      double dbu_uu)
{
    int    index;
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;
    unsigned short int presentation = 0;
    double   fstep;
    long int istep;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(textType, 0);
    wrstrm();

    if (fontType)
    {
        if (fontType == 3)
        {
            presentation |= 0x30;
        }
        else if (fontType == 2)
        {
            presentation |= 0x20;
        }
        else if (fontType == 1)
        {
            presentation |= 0x10;
        }
    }
    if (strlen(textJust) == 2)
    {
        if (strncmp(textJust,"tl",2)) // default
        {
            if (textJust[0] == 'b')
            {
                presentation |= 0x8;
            }
            else if (textJust[0] == 'm')
            {
                presentation |= 0x4;
            }

            if (textJust[1] == 'r')
            {
                presentation |= 0x2;
            }
            else if (textJust[1] == 'c')
            {
                presentation |= 0x1;
            }
        }
    }
    if (presentation)
    {
        // WRITE PRESENTATION
        Length = 2;
        Rectyp = PRESENTATION;
        Dattyp = BIT_ARRAY;             // bit array
        putI16(presentation, 0);
        wrstrm();
    }
    // WRITE PATHTYPE
    Length = 2;
    Rectyp = PATHTYPE;
    Dattyp = INTEGER_2;
    putI16(pathType, 0);
    wrstrm();

    fstep = (double) (width + epsilon) * factor; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    if (istep)
    {
        // WRITE WIDTH
        Length = 4;
        Rectyp = WIDTH;
        Dattyp = INTEGER_4;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    if (mag != 1.0)
    {
        Length = 8;
        Rectyp = MAG;
        Dattyp = REAL_8;
        putDbl(mag, 0);
        wrstrm();
    }

    // WRITE ANGLE
    if (angle != 0.0)
    {
        Length = 8;
        Rectyp = ANGLE;
        Dattyp = REAL_8;
        putDbl(angle, 0);
        wrstrm();
    }

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + epsilon) * factor), 0); }
    else          { putI32((long int)((x - epsilon) * factor), 0); }
    if (y >= 0.0) { putI32((long int)((y + epsilon) * factor), 4); }
    else          { putI32((long int)((y - epsilon) * factor), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();
}


//*********** putText *********************
//* PUTS A TEXT RECORD ON SPECIFIED LAYER *
//* layer must be >=0 && <=64K            *
//*****************************************
//#  <text>::=          TEXT [ELFLAGS] [PLEX] LAYER <textbody>                   #
//#                                                                              #
//#  <textbody>::=      TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY #
//#                     STRING                                                   #
//#                                                                              #
//#  <strans>::=        STRANS [MAG] [ANGLE]                                     #
void GDSFILE::putText(unsigned short layer,
                      unsigned short textType,
                      unsigned short fontType,
                      char*          textJust,
                      unsigned short pathType,
                      double         width,
                      unsigned short ref,
                      double         mag,
                      double         angle,
                      double         x,
                      double         y,
                      char*          txt,
                      double dbu_uu)
{
    double factor = (1 / dbu_uu);
    double epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;
    unsigned short int presentation = 0;
    double   fstep;
    long int istep;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(textType, 0);
    wrstrm();

    if (fontType)
    {
        if (fontType == 3)
        {
            presentation |= 0x30;
        }
        else if (fontType == 2)
        {
            presentation |= 0x20;
        }
        else if (fontType == 1)
        {
            presentation |= 0x10;
        }
    }
    if (strlen(textJust) == 2)
    {
        if (strncmp(textJust,"tl",2)) // default
        {
            if (textJust[0] == 'b')
            {
                presentation |= 0x8;
            }
            else if (textJust[0] == 'm')
            {
                presentation |= 0x4;
            }

            if (textJust[1] == 'r')
            {
                presentation |= 0x2;
            }
            else if (textJust[1] == 'c')
            {
                presentation |= 0x1;
            }
        }
    }
    if (presentation)
    {
        // WRITE PRESENTATION
        Length = 2;
        Rectyp = PRESENTATION;
        Dattyp = BIT_ARRAY;             // bit array
        putI16(presentation, 0);
        wrstrm();
    }
    // WRITE PATHTYPE
    Length = 2;
    Rectyp = PATHTYPE;
    Dattyp = INTEGER_2;
    putI16(pathType, 0);
    wrstrm();

    fstep = (double) (width + epsilon) * factor; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    if (istep)
    {
        // WRITE WIDTH
        Length = 4;
        Rectyp = WIDTH;
        Dattyp = INTEGER_4;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    if (mag != 1.0)
    {
        Length = 8;
        Rectyp = MAG;
        Dattyp = REAL_8;
        putDbl(mag, 0);
        wrstrm();
    }

    // WRITE ANGLE
    if (angle != 0.0)
    {
        Length = 8;
        Rectyp = ANGLE;
        Dattyp = REAL_8;
        putDbl(angle, 0);
        wrstrm();
    }

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + epsilon) * factor), 0); }
    else          { putI32((long int)((x - epsilon) * factor), 0); }
    if (y >= 0.0) { putI32((long int)((y + epsilon) * factor), 4); }
    else          { putI32((long int)((y - epsilon) * factor), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE ENDEL
    endEl();
}


//*********** putText *********************
//* PUTS A TEXT RECORD ON SPECIFIED LAYER *
//* layer must be >=0 && <=64K            *
//*****************************************
//#  <text>::=          TEXT [ELFLAGS] [PLEX] LAYER <textbody>                   #
//#                                                                              #
//#  <textbody>::=      TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY #
//#                     STRING                                                   #
//#                                                                              #
//#  <strans>::=        STRANS [MAG] [ANGLE]                                     #
void GDSFILE::putText(unsigned short layer,
                      unsigned short textType,
                      unsigned short fontType,
                      char*          textJust,
                      unsigned short pathType,
                      double         width,
                      unsigned short ref,
                      double         mag,
                      double         angle,
                      double         x,
                      double         y,
                      char*          txt)
{
    unsigned short int presentation = 0;
    double   fstep;
    long int istep;

    // WRITE TEXT
    Length = 0;
    Rectyp = TEXT;
    Dattyp = NO_DATA;
    wrstrm();

     // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE TEXTTYPE
    Length = 2;
    Rectyp = TEXTTYPE;
    Dattyp = INTEGER_2;
    putI16(textType, 0);
    wrstrm();

    if (fontType)
    {
        if (fontType == 3)
        {
            presentation |= 0x30;
        }
        else if (fontType == 2)
        {
            presentation |= 0x20;
        }
        else if (fontType == 1)
        {
            presentation |= 0x10;
        }
    }
    if (strlen(textJust) == 2)
    {
        if (strncmp(textJust,"tl",2)) // default
        {
            if (textJust[0] == 'b')
            {
                presentation |= 0x8;
            }
            else if (textJust[0] == 'm')
            {
                presentation |= 0x4;
            }

            if (textJust[1] == 'r')
            {
                presentation |= 0x2;
            }
            else if (textJust[1] == 'c')
            {
                presentation |= 0x1;
            }
        }
    }
    if (presentation)
    {
        // WRITE PRESENTATION
        Length = 2;
        Rectyp = PRESENTATION;
        Dattyp = BIT_ARRAY;             // bit array
        putI16(presentation, 0);
        wrstrm();
    }
    // WRITE PATHTYPE
    Length = 2;
    Rectyp = PATHTYPE;
    Dattyp = INTEGER_2;
    putI16(pathType, 0);
    wrstrm();

    fstep = (double) (width + G_epsilon) * 1000; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    if (istep)
    {
        // WRITE WIDTH
        Length = 4;
        Rectyp = WIDTH;
        Dattyp = INTEGER_4;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE STRANS
    Length = 2;
    Rectyp = STRANS;
    Dattyp = BIT_ARRAY;             // bit array
    putI16(ref * 0x8000, 0);
    wrstrm();

    // WRITE MAG
    if (mag != 1.0)
    {
        Length = 8;
        Rectyp = MAG;
        Dattyp = REAL_8;
        putDbl(mag, 0);
        wrstrm();
    }

    // WRITE ANGLE
    if (angle != 0.0)
    {
        Length = 8;
        Rectyp = ANGLE;
        Dattyp = REAL_8;
        putDbl(angle, 0);
        wrstrm();
    }

    // WRITE XY
    Length = 8;
    Rectyp = XY;
    Dattyp = INTEGER_4;
    if (x >= 0.0) { putI32((long int)((x + G_epsilon) * 1000), 0); }
    else          { putI32((long int)((x - G_epsilon) * 1000), 0); }
    if (y >= 0.0) { putI32((long int)((y + G_epsilon) * 1000), 4); }
    else          { putI32((long int)((y - G_epsilon) * 1000), 4); }
    wrstrm();

    // WRITE STRING
    strcpy(Record, txt);
    Length = strlen(Record);
    if (Length%2) {
        Record[Length]     = '\0';
        Record[Length + 1] = '\0';
        Length++;
    }
    Rectyp = STRING;
    Dattyp = ACSII_STRING;
    wrstrm();

    // WRITE ENDEL
    endEl();
}


// PUTS AN N-SIDED BOUNDARY ON A SPECIFIED LAYER
int GDSFILE::putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, double dbu_uu)
{
    int      index;
    double   fstep;
    long int istep;
    double   factor = (1 / dbu_uu);
    double   epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;             // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep = (double) (xArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (xArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep = (double) (yArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (yArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        if (fstep >= 0.0) { fstep += epsilon; }
        else              { fstep -= epsilon; }
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    if (xArray[0] != xArray[nVert - 1] && yArray[0] != yArray[nVert - 1])
    {
        if (xArray[0] >= 0.0) { fstep = (double) (xArray[0] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (xArray[0] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8));

        if (yArray[0] >= 0.0) { fstep = (double) (yArray[0] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (yArray[0] - epsilon) * factor; } // done in steps because of previous compilier bug
        if (fstep >= 0.0) { fstep += epsilon; }
        else              { fstep -= epsilon; }
        istep = (long int) fstep;
        putI32(istep, (index * 8) + 4);
        Length += 8;
    }
    wrstrm();

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-SIDED BOUNDARY ON A SPECIFIED LAYER
int GDSFILE::putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert)
{
    int      index;
    double   fstep;
    long int istep;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;             // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep = (double) (xArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (xArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep = (double) (yArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (yArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    if (xArray[0] != xArray[nVert - 1] && yArray[0] != yArray[nVert - 1])
    {
        if (xArray[0] >= 0.0) { fstep = (double) (xArray[0] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (xArray[0] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8));

        if (yArray[0] >= 0.0) { fstep = (double) (yArray[0] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (yArray[0] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8) + 4);
        Length += 8;
    }
    wrstrm();

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-SIDED BOUNDARY ON A SPECIFIED LAYER
int GDSFILE::putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double dbu_uu)
{
    int      index;
    double   fstep;
    long int istep;
    double   factor = (1 / dbu_uu);
    double   epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;             // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep = (double) (xArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (xArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep = (double) (yArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (yArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    if (xArray[0] != xArray[nVert - 1] && yArray[0] != yArray[nVert - 1])
    {
        if (xArray[0] >= 0.0) { fstep = (double) (xArray[0] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (xArray[0] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8));

        if (yArray[0] >= 0.0) { fstep = (double) (yArray[0] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (yArray[0] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8) + 4);
        Length += 8;
    }
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();

    return 0;
}

// PUTS AN N-SIDED BOUNDARY ON A SPECIFIED LAYER
int GDSFILE::putBndDbl(int layer, int datatyp, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING])
{
    int      index;
    double   fstep;
    long int istep;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;             // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep = (double) (xArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (xArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep = (double) (yArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep = (double) (yArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    if (xArray[0] != xArray[nVert - 1] && yArray[0] != yArray[nVert - 1])
    {
        if (xArray[0] >= 0.0) { fstep = (double) (xArray[0] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (xArray[0] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8));

        if (yArray[0] >= 0.0) { fstep = (double) (yArray[0] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                  { fstep = (double) (yArray[0] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index * 8) + 4);
        Length += 8;
    }
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-SIDED BOUNDARY ON A SPECIFIED LAYER --- note: 1.0 = 1000
int GDSFILE::putBndInt(int layer, int datatyp, int xArray[], int yArray[], int nVert)
{
    int     index;

    // WRITE BOUNDARY
    Length = 0;
    Rectyp = BOUNDARY;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;             // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        putI32(xArray[index], (index*8));
        putI32(yArray[index], (index*8) + 4);
    }
    if (xArray[0] != xArray[nVert - 1] && yArray[0] != yArray[nVert - 1])
    {
        putI32(xArray[0], (index*8));
        putI32(yArray[0], (index*8) + 4);
        Length += 8;
    }
    wrstrm();

    // WRITE ENDEL
    endEl();
    return 0;
}

// PUTS AN N-point PATH ON A SPECIFIED LAYER --- note: 1.0 = 1000 */
// <path>::= PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE] [WIDTH] [BGNEXTN] [ENDEXTN] [XY]
int GDSFILE::putPathDbl(int layer, int datatyp, int pathtyp, double width, double bgnextn, double endextn, double xArray[], double yArray[], int nVert, int propIndex, int propNumArray[], char propValueArray[][LENGTHLSTRING], double dbu_uu)
{
    int      index;
    double   fstep;
    long int istep;
    double   factor = (1 / dbu_uu);
    double   epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE PATH
    Length = 0;
    Rectyp = PATH;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    if (pathtyp > 0)
    {
        // WRITE PATHTYPE
        Length = 2;
        Rectyp = PATHTYPE;
        Dattyp = INTEGER_2;
        putI16(pathtyp, 0);
        wrstrm();
    }

    // WRITE WIDTH
    Length = 4;
    Rectyp = WIDTH;
    Dattyp = INTEGER_4;
    fstep = (double) (width + epsilon) * factor; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    putI32(istep, 0);
    wrstrm();

    if (pathtyp == 4)
    {
        // WRITE BGNEXTN
        Length = 4;
        Rectyp = BGNEXTN;
        Dattyp = INTEGER_4;
        if (bgnextn >= 0.0) { fstep =  (double) (bgnextn + epsilon) * factor; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (bgnextn - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();

        // WRITE ENDEXTN
        Length = 4;
        Rectyp = ENDEXTN;
        Dattyp = INTEGER_4;
        if (endextn >= 0.0) { fstep =  (double) (endextn + epsilon) * factor; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (endextn - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE XY
    Length = nVert * 8;       // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep =  (double) (xArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (xArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep =  (double) (yArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (yArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    wrstrm();

    for (index=0; index <= propIndex; index++)
    {
        Length = 2;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPATTR;
        Dattyp = INTEGER_2;
        putI16(propNumArray[index], 0);
        wrstrm();

        Length = 4;             // N, 4 byte records of xArray, and yArray
        Rectyp = PROPVALUE;
        Dattyp = ACSII_STRING;
        strcpy(Record, propValueArray[index]);
        Length = strlen(Record);
        if (Length%2) {
            Record[Length]     = '\0';
            Record[Length + 1] = '\0';
            Length++;
        }
        wrstrm();
    }

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-point PATH ON A SPECIFIED LAYER --- note: 1.0 = 1000 */
// <path>::= PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE] [WIDTH] [BGNEXTN] [ENDEXTN] [XY]
int GDSFILE::putPathDbl(int layer, int datatyp, int pathtyp, double width, double bgnextn, double endextn, double xArray[], double yArray[], int nVert, double dbu_uu)
{
    int      index;
    double   fstep;
    long int istep;
    double   factor = (1 / dbu_uu);
    double   epsilon = (dbu_uu / 20.0);
    if (G_epsilon < epsilon) epsilon = G_epsilon;

    // WRITE PATH
    Length = 0;
    Rectyp = PATH;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    if (pathtyp > 0)
    {
        // WRITE PATHTYPE
        Length = 2;
        Rectyp = PATHTYPE;
        Dattyp = INTEGER_2;
        putI16(pathtyp, 0);
        wrstrm();
    }

    // WRITE WIDTH
    Length = 4;
    Rectyp = WIDTH;
    Dattyp = INTEGER_4;
    fstep = (double) (width + epsilon) * factor; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    putI32(istep, 0);
    wrstrm();

    if (pathtyp == 4)
    {
        // WRITE BGNEXTN
        Length = 4;
        Rectyp = BGNEXTN;
        Dattyp = INTEGER_4;
        if (bgnextn >= 0.0) { fstep =  (double) (bgnextn + epsilon) * factor; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (bgnextn - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();

        // WRITE ENDEXTN
        Length = 4;
        Rectyp = ENDEXTN;
        Dattyp = INTEGER_4;
        if (endextn >= 0.0) { fstep =  (double) (endextn + epsilon) * factor; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (endextn - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE XY
    Length = nVert * 8;       // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep =  (double) (xArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (xArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep =  (double) (yArray[index] + epsilon) * factor; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (yArray[index] - epsilon) * factor; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    wrstrm();

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-point PATH ON A SPECIFIED LAYER --- note: 1.0 = 1000 */
// <path>::= PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE] [WIDTH] [BGNEXTN] [ENDEXTN] [XY]
int GDSFILE::putPathDbl(int layer, int datatyp, int pathtyp, double width, double bgnextn, double endextn, double xArray[], double yArray[], int nVert)
{
    int      index;
    double   fstep;
    long int istep;

    // WRITE PATH
    Length = 0;
    Rectyp = PATH;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    if (pathtyp > 0)
    {
        // WRITE PATHTYPE
        Length = 2;
        Rectyp = PATHTYPE;
        Dattyp = INTEGER_2;
        putI16(pathtyp, 0);
        wrstrm();
    }

    // WRITE WIDTH
    Length = 4;
    Rectyp = WIDTH;
    Dattyp = INTEGER_4;
    fstep = (double) (width + G_epsilon) * 1000; // done in steps because of previous compilier bug
    istep = (long int) fstep;
    putI32(istep, 0);
    wrstrm();

    if (pathtyp == 4)
    {
        // WRITE BGNEXTN
        Length = 4;
        Rectyp = BGNEXTN;
        Dattyp = INTEGER_4;
        if (bgnextn >= 0.0) { fstep =  (double) (bgnextn + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (bgnextn - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();

        // WRITE ENDEXTN
        Length = 4;
        Rectyp = ENDEXTN;
        Dattyp = INTEGER_4;
        if (endextn >= 0.0) { fstep =  (double) (endextn + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                { fstep =  (double) (endextn - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, 0);
        wrstrm();
    }

    // WRITE XY
    Length = nVert * 8;       // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++)
    {
        if (xArray[index] >= 0.0) { fstep =  (double) (xArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (xArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8));

        if (yArray[index] >= 0.0) { fstep =  (double) (yArray[index] + G_epsilon) * 1000; } // done in steps because of previous compilier bug
        else                      { fstep =  (double) (yArray[index] - G_epsilon) * 1000; } // done in steps because of previous compilier bug
        istep = (long int) fstep;
        putI32(istep, (index*8) + 4);
    }
    wrstrm();

    // WRITE ENDEL
    endEl();

    return 0;
}


// PUTS AN N-point PATH ON A SPECIFIED LAYER --- note: 1.0 = 1000 */
int GDSFILE::putPathInt(int layer, int datatyp, int width, int xArray[], int yArray[], int nVert)
{
    int  index;

    // WRITE PATH
    Length = 0;
    Rectyp = PATH;
    Dattyp = NO_DATA;
    wrstrm();

    // WRITE LAYER
    Length = 2;
    Rectyp = LAYER;
    Dattyp = INTEGER_2;
    putI16(layer, 0);
    wrstrm();

    // WRITE DATATYPE
    Length = 2;
    Rectyp = DATATYPE;
    Dattyp = INTEGER_2;
    putI16(datatyp, 0);
    wrstrm();

    // WRITE WIDTH
    Length = 4;
    Rectyp = WIDTH;
    Dattyp = INTEGER_4;
    putI32(width, 0);
    wrstrm();

    // WRITE XY
    Length = nVert * 8;       // N, 4 byte records of xArray, and yArray
    Rectyp = XY;
    Dattyp = INTEGER_4;
    for (index=0; index < nVert; index++) {
        putI32(xArray[index], (index*8));
        putI32(yArray[index], (index*8) + 4);
    }
    wrstrm();

    // WRITE ENDEL
    endEl();

    return 0;
}


void GDSFILE::copyRecord(char* copy)    //copy current record to "copy"
{
    char* ptr = record();
    for(int i=0; i<204800; i++) copy[i] = *ptr++;
}


////////////////////////////////////////////////
int GDSFILE::roundInt(int input, int round2grid)
{
    if (input > 0 ) return(((input + (round2grid/2))/round2grid ) * round2grid);
    else            return(((input - (round2grid/2))/round2grid ) * round2grid);
}

// mystrncpy.C
// Copyright 2014 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: mystrncpy.C 96 2013-05-22 20:50:29Z schumack $
/*****    mystrncpy  ********************************************************/
/* "safe" strcpy -kvs                                                       */
/****************************************************************************/

char* mystrncpy(char *dest, char *src, size_t n)
{
  src[n] = '\0';
  strcpy(dest, src);
  return(dest);
}

// sRemoveSpaces.C
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: sRemoveSpaces.C 69 2010-09-24 20:14:21Z schumack $ 
 
/***** SREMOVESPACES ********************************************************/
/* Removes all occurances of a spaces & tabs in a string             -kvs   */
/****************************************************************************/
char* sRemoveSpaces(char* parent, char* child)
{
  int i, j, length;
  
  length = strlen(parent);
  for(i=0, j=0; i<length; i++) 
    {
      if (!(parent[i] == ' ' || parent[i] == '\t')) 
        {
	  child[j] = parent[i];
	  j++;
        }
    }
  child[j] = '\0';
  return(child);
}

// sRemoveTrailingZeros.C
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: sRemoveTrailingZeros.C 81 2010-09-24 20:14:33Z schumack $ 

/***** sRemoveTrailingZeros *********************************************/
/* Remove zeros at the end of a real number string                 -kvs */
/************************************************************************/
char* sRemoveTrailingZeros(char* inString, char* outString)
{
  int i, done;
  done = 0;
  inString[LENGTHSSTRING] = '\0'; //safety
  strcpy(outString,inString);
  
  for(i=strlen(inString); (i>0) && (! done); i--) 
    {
      if (inString[i] == '.')
        {
	  outString[i] = '\0';
	  done = 1;
	  break;
        }
      else if ((inString[i] != '0') && (inString[i] != '\0'))
        {
	  done = 1;
	  break;
        }
      else
        {
	  outString[i] = '\0';
        }
    }
  return(outString);
}



// sRemoveWhiteSpace.C
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: sRemoveWhiteSpace.C 71 2010-09-24 20:14:23Z schumack $  

/***** SREMOVEWHITESPACE ****************************************************/
/* Removes all occurances of white space in a string                 -kvs   */
/****************************************************************************/
char* sRemoveWhiteSpace(char* parent, char* child)
{
  int i, j, length;
  
  length = strlen(parent);
  for(i=0, j=0; i<length; i++) 
    {
      if (!(parent[i] == ' ' || parent[i] == '\t' || parent[i] == '\n' || parent[i] == '\r')) 
        {
	  child[j] = parent[i];
	  j++;
        }
    }
  child[j] = '\0';
  return(child);
}

//stoupper.C
// Copyright 1995-2010 by Ken Schumack (Schumack@cpan.org)
// @(#) $Id: stoupper.C 83 2010-09-24 20:14:35Z schumack $ 
/***** STOUPPER **************************************************************/
/* uses toupper repeatedly on a string   -kvs                                */
/*****************************************************************************/
char* stoupper(char* string, char* upstring)
{
  while (*string != '\0') 
    {
      if (islower(*string))  *upstring++ = toupper(*string++);
      else                   *upstring++ = *string++;
    }
  *upstring = '\0';       /* add null back on for end of string */
  return(upstring);
}

unsigned int isIntegerString(char *str) {
  //  Checks that all charters in a string are digits.
  while (*str != 0) {
    if (!isdigit(*str)) {
      return(0);
    }
    str++;
  }
  return(1);
}

unsigned int legalDatatype(long dataType) {
  int i;

  if (pinGeomDatatypeCount < 0) {return(1);}    // All datatypes are legal.

  for (i=0; (i<pinGeomDatatypeCount); i++) {
    if (pinGeomDatatype[pinGeomDatatypeCount] == dataType) {
      return(1);
    }
  }
  return(0);
}

bool CheckCoordsInsidePolygon( long int x, long int y, long int * xylist, int sizeOfArray ) {
  // Original taken from msip_hipreGDSIICellPinInfo.C, modified to take single xylist instead of separate xlist/ylist.
  int   result=0, ix, iy, jx, jy, last;
  double xeval;
  if (sizeOfArray < 8) {
    return(0);
  }  //  Don't even try with any polygon less than this.
  last=sizeOfArray-1;
  //j=sides-1;  //  Original code: j would be index of next-to-last coord. Last one should actually be duplicate of first.
  jx=last-3;
  jy=last-2;
  for (ix=0; ix<(last-1); ix+=2) {
    iy = ix+1;
    if ((xylist[iy]<y  &&  xylist[jy]>=y) || (xylist[jy]<y && xylist[iy]>=y)) {
      xeval =xylist[ix]+double(double(y-xylist[iy])/double(xylist[jy]-xylist[iy]))*(xylist[jx]-xylist[ix]) ;
      if (xeval<x) {
	result=!result;
      }
    }
    jx=ix;
    jy=iy;
  }
  return result;
}

bool CheckCoordsInsidePath( long int x, long int y, long int pathWidth, long int * xylist, int counter ) {
  // Original taken from msip_hipreGDSIICellPinInfo.C, modified to take single xylist instead of separate xlist/ylist.
  int      result=0, ix, iy ;
  long int dx_one2point,dy_one2point,dx_line,dy_line;
  double   lengthLineSQ,parallelCheck,a,b,halfPathWidth=float(pathWidth/2);
  
  for (ix=0; ix<counter-2; ix+=2) {
    iy = ix + 1;
    dx_one2point  = xylist[ix] - x;
    dy_one2point  = xylist[iy] - y;
    dx_line       = xylist[ix+2] - xylist[ix];
    dy_line       = xylist[iy+2] - xylist[iy];
    lengthLineSQ  = double(dx_line * dx_line + dy_line * dy_line);
    parallelCheck = double(-dx_one2point * dx_line) + double(-dy_one2point * dy_line);   //if this is < 0 or > length then its outside the line segment
    if ((parallelCheck>0) && (parallelCheck< lengthLineSQ)) {
      a = double(dx_line * dy_one2point) - double(dy_line * dx_one2point);
      b = (a * a) / lengthLineSQ;
      if (b < (halfPathWidth*halfPathWidth)) {
	result=1;
      }
    }
  }
  return result;
}
void dbgPrint(char *str) {
  printf("%s", str);
}

struct geomRec *newGeomRec (long layer, long dataType, long *xyArray, int nXY) {
  struct geomRec *gRec;
  long *lp;
  int i;
  
  gRec = (struct geomRec *) myMalloc(sizeof(struct geomRec));
  gRec->layer = layer;
  gRec->dataType = dataType;
  gRec->width = 0;
  gRec->isRect = 0;
  gRec->boundary = 0;
  gRec->isPrBoundary = 0;
  gRec->path = 0;
  gRec->minX = 0;
  gRec->minY = 0;
  gRec->maxX = 0;
  gRec->maxY = 0;
  gRec->textCount = 0;
  gRec->textList = NULL;
  gRec->textListEnd = NULL;
  gRec->next = NULL;

  // Copy xy array
  gRec->coords = (long *) myMalloc(sizeof(long)*nXY);
  lp = gRec->coords;
  for (i=0; (i<nXY); i++) {*lp++ = *xyArray++;}
  gRec->nCoords = nXY;

  return gRec;

}



Boolean checkDamnClose(long x0, long y0, long x1, long y1, int delta) {
  // Checks for a dead-on match. In this case, dead-on is within one gds unit
  
  if (x1 < (x0-delta)) return 0;
  if (x1 > (x0+delta)) return 0;
  if (y1 < (y0-delta)) return 0;
  if (y1 > (y0+delta)) return 0;
  return 1;

}

Boolean checkExact(long x0, long y0, long x1, long y1) {
  
  if (x1 < x0) return 0;
  if (x1 > x0) return 0;
  if (y1 < y0) return 0;
  if (y1 > y0) return 0;
  return 1;

}

void findBumpMatches(struct gdsStruct *phyGds, struct gdsStruct *gds2) {
  //  Looks for bumps matches between two gds's

  struct textRec *t1, *t2;
  long xMin, xMax, yMin, yMax;
  char x1s[20], y1s[20], x2s[20], y2s[20], x0s[20], y0s[20], xs[20], ys[20];
  int clean = 1;
  
  logMsg("");
  sprintf(msg, "Checking for bump matches"); logInfo(msg);
  //sprintf(msg, "       phyGds = %s\n", phyGds->fileName); logInfo(msg);
  //sprintf(msg, "       intGds = %s\n", intGds->fileName); logInfo(msg);

  clean = 1;
  for (t1=phyGds->textList; (t1!=NULL); t1=t1->next) {
    xMin = t1->tx - bumpWindowDelta;
    xMax = t1->tx + bumpWindowDelta;
    yMin = t1->ty - bumpWindowDelta;
    yMax = t1->ty + bumpWindowDelta;
    
    //printf("Info: Checking PHY bump %s\n", t1->text);
    for (t2=intGds->textList; (t2!=NULL); t2=t2->next) {
      //  Loop through remaining texts
      //printf("     Checking int bump %s\n", t2->text);
      if (t2->tx < xMin) continue;
      if (t2->tx > xMax) continue;
      if (t2->ty < yMin) continue;
      if (t2->ty > yMax) continue;
      //  Must be within the box.  We have a match.
      //printf("Matched %s  %s\n", t1->text, t2->text);
      t1->connText = t2;
      t2->connText = t1;
      if (checkExact(t1->tx, t1->ty, t2->tx, t2->ty)) {
	t1->deadOn = t2->deadOn = 1;
	t1->damnClose = t2->damnClose = 0;
      } else {
	if (checkDamnClose(t1->tx, t1->ty, t2->tx, t2->ty, 1)) {
	  t1->damnClose = t2->damnClose = 1;
	} else {
	  t1->deadOn = t2->deadOn = 0;
	}
      }

      //printf("!!!   %s -->  %s\n", t1->mapped, t2->text);
      if (t1->mapped != NULL) {
	if (!strEqualNocase(t1->mapped, t2->text)) {
	  //  Matched bump not named as expected.
          t1->nameMismatch = 1;
	  clean = 0;
	}
      }
    }
  }
}

void dumpTexts(struct gdsStruct *gds) {
  //  Loop through phy bumps looking for multiple labels within the same window.
  
  struct textRec *t, *t1;
  long xMin, xMax, yMin, yMax;
  char xs[20], ys[20], x1s[20], y1s[20];
  int clean = 1;
  int i = 0;
  printf("Dumping texts in %s\n", gds->fileName);
  
  //printf("gds text %d  %ld\n", i, (long int)gds->textList);
  for (t=gds->textList; (t!=NULL); t=t->next) {
    printf("DMP %s  %ld,%ld\n", t->text, t->x, t->y);
  }
}

void findExtraLabels(struct gdsStruct *gds) {
  //  Loop through phy bumps looking for multiple labels within the same window.
  
  struct textRec *t, *t1;
  long xMin, xMax, yMin, yMax;
  char xs[20], ys[20], x1s[20], y1s[20];
  int clean = 1;
  int i = 0;
  sprintf(msg, "Checking %s for extra label instances", gds->fileName); logInfo(msg);
  
  //printf("gds text %d  %ld\n", i, (long int)gds->textList);
  for (t=gds->textList; (t!=NULL); t=t->next) {
    xMin = t->x - bumpWindowDelta;
    xMax = t->x + bumpWindowDelta;
    yMin = t->y - bumpWindowDelta;
    yMax = t->y + bumpWindowDelta;
    for (t1=t->next; (t1!=NULL); t1=t1->next) {
      //  Loop through remaining texts
      if (t1->x < xMin) {continue;}
      if (t1->x > xMax) {continue;}
      if (t1->y < yMin) {continue;}
      if (t1->y > yMax) {continue;}
      //  Must be within the box.
      fmtCoord(t->x, xs);
      fmtCoord(t->y, ys);
      fmtCoord(t1->x, x1s);
      fmtCoord(t1->y, y1s);
      if (strEqualNocase(t->text, t1->text)) {
        sprintf(msg, "Found extra matching bump label:  %s @(%s,%s) & %s @(%s,%s)", t->text, xs, ys, t1->text, x1s, y1s); logInfo(msg);
      } else {
        sprintf(msg, "Found extra mismatched bump label:  %s @(%s,%s) & %s @(%s,%s)", t->text, xs, ys, t1->text, x1s, y1s); logError(msg);
      }
      clean = 0;
    }
  } 
  if (clean) {
    logInfo("Extra label instances check Clean!\n");
  }

}			     
/*
**++
**  FACILITY:
**
**      stredit: String edit facility
**
**  ABSTRACT:
**
**	    Procedure to edit a string. Permissable operations and their
**	    associated keywords are:
**
**		Keyword	    Operation
**		------------------------------------------------------------
**		COLLAPSE:   Remove all blanks and tabs
**		COMPRESS:   Replace all blanks and tabs with a single space
**		LOWERCASE:  Convert to lowercase
**		TRIM:	    Removed leading and trailing blanks
**		UNCOMMENT:  Remove comments, as delimted by the '#' character
**		UPCASE:	    Convert to uppercase
**
**	    The operation is specified by a string containing a list of these
**	    keywords.  Keywords are case-insensitive and are delimited by
**	    spaces and/or tabs and/or commas.
**
**  AUTHORS:
**
**      John Clouser
**
**
**  CREATION DATE:     21-NOV-1988
**
**  MODIFICATION HISTORY:
**
**  21-NOV-1988	    J. Clouser	    Creation
**--
**/

#define	    _isblank(c)	    ( (c == ' ') || (c == '\011') || (c == '\n') )


/**************************  ROUTINE DECLARATIONS  ****************************/
/*
**++
**    FUNCTIONAL DESCRIPTION:
**
**      stredit:  String edit procedure
**
**	    Procedure to edit a string. Permissable operations and their
**	    associated keywords are:
**
**		Keyword	    Operation
**		------------------------------------------------------------
**		COLLAPSE:   Remove all blanks and tabs
**		COMPRESS:   Replace all blanks and tabs with a single space
**		LOWERCASE:  Convert to lowercase
**		TRIM:	    Removed leading and trailing blanks
**		UNCOMMENT:  Remove comments, as delimted by the '#' character
**		UPCASE:	    Convert to uppercase
**
**	    The operation is specified by a string containing a list of these
**	    keywords.  Keywords are case-insensitive and are delimited by
**	    spaces and/or tabs and/or commas.
**
**  FORMAL PARAMETERS:
**
**      char	*string;	    String to be edited, modified
**	char	*oplist;	    Edit operation list.
**
**  IMPLICIT INPUTS:
**
**      The formal parameter "string" is modified according to the edit list
**
**  IMPLICIT OUTPUTS:
**
**      None
**
**  COMPLETION CODES:
**
**      None
**
**  SIDE EFFECTS:
**
**      Changes input string
**
**--
**/

void stredit(char *string, char *oplistin)
{
  int	    i;
  char    *token;
  char    *in, *out;		/*  String output and input pointers		*/
  char    editop,		/*  Edit operation mask				*/
    quote,		/*  Quote flag					*/
    nb_start,		/*  Start of non-blanl sequence flag		*/
    end,		/*  Logical end-of-edit flag			*/
    *nb_end,		/*  Last non-blank character pointer		*/
    oplist[100];	/*  Local copy of oplist, for strtok'ing	*/
  
  
  strcpy(oplist, oplistin);							/*  Must make local copy because strtok		*/
										/*  will munge the oplist.			*/
  editop = 0;
  token = (char *) strtok(oplist, ", \011");
  while (token != NULL)
    {
      for(i=0; (i<strlen(token)); i++) token[i] = _toupper(token[i]);		/*  Convert operation to uppercase  */
      if (!strcmp(token, "COLLAPSE"))	    editop = editop | 0x01;
      if (!strcmp(token, "COMPRESS"))	    editop = editop | 0x02;
      if (!strcmp(token, "LOWERCASE"))    editop = editop | 0x04;
      if (!strcmp(token, "TRIM"))	    editop = editop | 0x08;
      if (!strcmp(token, "UNCOMMENT"))    editop = editop | 0x10;
      if (!strcmp(token, "UPCASE"))	    editop = editop | 0x20;
      token = (char *) strtok(NULL, ", \011");
    }
  
  /*  Having picked apart the edit list, now do the editing   */
  
  in = out = string;								/*  Init the input/output pointers	*/
  quote = FALSE;								/*  Init the quote flag			*/
  nb_start = FALSE;								/*  Init the non-blank found flag	*/
  nb_end = string;								/*  Init the last non-blank pointer	*/
  end = FALSE;
  
  do
    {
      if (quote)
        {
	  if (*in == '\"')
            {
	      quote = FALSE;							/*  Clear quote flag			*/
	    }
	  nb_end = out;							/*  Handles case where \" is last char  */
	  *out++ = *in++;							/*  Copy verbatim, no edit		*/
	}   /* End quote */
      else									/*  Not quoted, edit as appropriate	*/
        {
	  if (_isblank(*in))							/*  Character is a space		*/
            {
	      
	      if ( (editop & 0x01) || ((editop & 0x08) && (!nb_start)))	/*  COLLAPSE, or TRIM leading, ignore	*/
		in++;
	      
	      else if (editop & 0x02)						/*  COMPRESS				*/
		{
		  *out++ = ' ';						/*  Insert space			*/
		  do in++; while(_isblank(*in));				/*  Find next non-space			*/
		}	/* End COMPRESS */
	      
	      else *out++ = *in++;
	      
	    }	/* End space */
	  else
            {
	      if ( (editop & 0x10) && (*in == '#') )				/*  UNCOMMENT				*/
		{
		  end = TRUE;
		  *out = 0;
                }
	      else
                {
		  if (*in == '\"') quote = TRUE;				/*  Start of quoted section		*/
		  nb_start = TRUE;
		  if (editop & 0x20) *out = _toupper(*in);			/*  UPCASE				*/
		  else if (editop & 0x04) *out = _tolower(*in);		/*  LOWERCASE				*/
		  else *out = *in;
		  end = (*in == 0);						/*  Mark end				*/
		  if (! end)
                    {
		      nb_end = out;
		      out++;
		      in++;
		    }
		  
		}
	      
            }	/* End non-space */
	  
	}  /* End non-quote */
      
    } while ( ! end );
  
  if (editop & 0x08) *(nb_end + 1) = 0;					/*  If TRIM, terminate at non-blank	*/
  
}

void applyMap(gdsStruct *gds, mapRec *mapList) {

  struct textRec *t;
  struct mapRec *m;
  int hits;
  char *lbkt, *rbkt;
  char bfr[100];
  int match;
  
  for (t=gds->textList; (t!=NULL); t=t->next) {
    hits = 0;
    //  Split pin name into root and index.
    t->root = strsto(t->text);
    if ((lbkt=strchr(t->root, '[')) != NULL) {
      rbkt=strchr(t->root, ']');
      *lbkt = *rbkt = 0;   // Strip off busbit
      t->busbit = atoi(lbkt+1);
    }
    for (m=mapList; (m!=NULL); m=m->next) {
      match = 0;
      if (m->hasBkt) {
	//  map phy string contains a bracket.  Compare to the full original name.
	if (strEqualNocase(t->text, m->phyName)) {
	  t->mapped = m->intName;
	  hits++;
	}
      } else {
	//  map phy string contains NO bracket.  Compare to the root name.
	if (strEqualNocase(t->root, m->phyName)) {
	  if (t->busbit >= 0) {sprintf(bfr, "%s[%d]", m->intName, t->busbit);} else {strcpy(bfr, m->intName);}
	  t->mapped = strsto(bfr);
	  hits++;
	}
      }
    }

    if (hits == 0) {
      // Check for prefix
      if (*mapPrefix != '\0') {
	sprintf(bfr, "%s%s", mapPrefix, t->text);
	t->mapped = strsto(bfr);
        //printf("DBG:  Mapping %s to %s\n", t->text,  t->mapped);
      } else {
	//printf("Warning:  No map entry found for PHY pin %s\n", t->text);
	// no map entry.  Assume an exact match
	t->mapped = t->text;
      }
    } else if (hits > 1) {
      printf("Error:  Multiple map entries found for PHY pin %s\n", t->text);
    } else {
      //      printf("Info:  %s mapped to %s\n", t->text, t->mapped);
    }
  }
  
}

void processPhyBoundary(gdsStruct *phyGds) {
  
  struct geomRec *g;
  long minX, minY, maxX, maxY, x, y;
  long *cp;
  int i;
  int first = 1;
  int multIdentical = 1;
  char minXs[30], minYs[30], maxXs[30], maxYs[30];
  
  if (phyGds->nBoundary == 0) {
    printf("Error:  No boundary geometry found in %s\n", phyGds->fileName);
    phyGds->boundaryDefined = 0;
  } else {
    minX = phyGds->geomList->minX;
    minY = phyGds->geomList->minY;
    maxX = phyGds->geomList->maxX;
    maxY = phyGds->geomList->maxY;
    phyGds->minX = minX;  phyGds->minY = minY; phyGds->maxX = maxX; phyGds->maxY = maxY;
    phyGds->boundaryDefined = 1;
    if (phyGds->nBoundary > 1) {
      //  More than one object.  Need to check for weirdness.
      sprintf(msg, "Multiple (%d) boundary geometry found in %s\n", phyGds->nBoundary, phyGds->fileName); logWarning(msg);
      fmtCoord(minX, minXs);
      fmtCoord(minY, minYs);
      fmtCoord(maxX, maxXs);
      fmtCoord(maxY, maxYs);
      sprintf(msg, "\t ll = (%s,%s), ur = (%s,%s)", minXs, minYs, maxXs, maxYs); logMsg(msg);
      for (g=phyGds->geomList->next; (g!=NULL); g=g->next) {
	fmtCoord(g->minX, minXs);
	fmtCoord(g->minY, minYs);
	fmtCoord(g->maxX, maxXs);
	fmtCoord(g->maxY, maxYs);
	//printf("\t ll = (%s,%s), ur = (%s,%s)\n", minXs, minYs, maxXs, maxYs);
	printf("\t ll = (%s,%s), ur = (%s,%s)\n", minXs, minYs, maxXs, maxYs);
	if ( (minX != g->minX) || (minY != g->minY) || (maxX != g->maxX)|| (maxY != g->maxY) ) {
	  multIdentical = 0;
	}
      }
      if (multIdentical) {
	logInfo("All are identical.\n");
      } else {
	logInfo("Differences exist.\n");
	phyGds->boundaryDefined = 0;
      }
    }
  }
  
  if (!phyGds->boundaryDefined) {
    printf("Info:  PHY boundary could not be determined from boundary layer. Inferring from bump label field\n");
    struct textRec *t;
    long setback;
    setback = long(floor( 0.5 + phyBumpEdgeSetback/userUnits));
    minX = phyGds->textList->x;
    minY = phyGds->textList->y;
    maxX = phyGds->textList->x;
    maxY = phyGds->textList->y;
    for (t=phyGds->textList->next; (t!=NULL); t=t->next) {
      if (t->x < minX) {minX = t->x;}
      if (t->x > maxX) {maxX = t->x;}
      if (t->y < minY) {minY = t->y;}
      if (t->y > maxY) {maxY = t->y;}
    }
    phyGds->minX = minX - setback;
    phyGds->maxX = maxX + setback;
    phyGds->minY = minY - setback;
    phyGds->maxY = maxY + setback;
    phyGds->boundaryDefined = 1;
  }
}

unsigned int CheckRequiredArg(char *argName, char *argValue) {
  if (*argValue == 0) {
    sprintf(msg,"Missing required arg \"%s\"",argName ); logError(msg);
    return 0;
  } else {
    return 1;
  }
}

