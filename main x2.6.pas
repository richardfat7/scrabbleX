{
   scrabble.pas
   
   Copyright 2013 Cheng Wai Fat <richardfat@ubuntu>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
   
}


program scrabble;

uses
    crt, dos;
    
type
    TCTime=record
        h: longint;
        m: longint;
        s: longint;
        ms: longint;
        tms: int64;
    end;
    
    TIcon=array[0..3] of string;
    
    TPlayer=record
        id: byte;
        name1: string;
        name2: string;
        hand: array[0..6] of char;
        mark: integer;
        time: TCTime;
        icon: TIcon;
        timeStore: TCTime;
        timeIsUp: boolean;
        isWinning: boolean;
    end;
    
    TBoardGrid=record
        x: smallint;
        y: smallint;
        c: char;
        s: boolean;
    end;
    
    TBoard=array[0..14, 0..14] of char;
    
    THistEntry=record
        uid: smallint;
        mark: integer;
        action: char;
        words: array[0..7] of string;
        time: TCTime;
        posx: array[0..6] of smallint;
        posy: array[0..6] of smallint;
        highestFormedWord: string;
        highestFormedWordScore: integer;
    end;
    
const
    boardPreSq: array[-7..7, -7..7] of byte=((4, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 1, 0, 0, 4),
                                        (0, 3, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 3, 0),
                                        (0, 0, 3, 0, 0, 0, 1, 0, 1, 0, 0, 0, 3, 0, 0),
                                        (1, 0, 0, 3, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 1),
                                        (0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0),
                                        (0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0),
                                        (0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0),
                                        (4, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 1, 0, 0, 4),
                                        (0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0),
                                        (0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0),
                                        (0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0),
                                        (1, 0, 0, 3, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 1),
                                        (0, 0, 3, 0, 0, 0, 1, 0, 1, 0, 0, 0, 3, 0, 0),
                                        (0, 3, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 3, 0),
                                        (4, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 1, 0, 0, 4));
    
    tilesScore: array[0..26] of byte=(1, 3, 3, 2, 1, 4, 2, 4, 1, 8, 5, 1, 3,
                                      1, 1, 3,10, 1, 1, 1, 1, 4, 4, 8, 4,10, 0);
    tilesAmount: array[0..26] of smallint=(9, 2, 2, 4,12, 2, 3, 2, 9, 1, 1, 4, 2,
                                           6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1, 2);
                                           
    defaultIcon: array[0..3] of TIcon=( ( ('  o  '),
                                          ('--+--'),
                                          ('  |  '),
                                          (' / \ ') ),
                                        ( ('  O  '),
                                          ('\-+-/'),
                                          ('  |  '),
                                          ('-/ \-') ),
                                        ( ('  o  '),
                                          ('/-+-\'),
                                          ('  |  '),
                                          (' J L ') ),
                                        ( ('  0  '),
                                          ('>-+-<'),
                                          ('  |  '),
                                          (' ^ ^ ') ) );
                                          
    baseColor=white;
    baseBackground=black;
    
var
//prog related
    i, j: smallint;
    k: integer;
    key: char;
    count, count2, count3: smallint;
    tmpChar: char;
    tmpStr: string;
    
//compatibility related
    OS: boolean;
        //TRUE if WIN, FALSE if UNIX
    
//game global
    bag: string;
    bagCount: smallint;
    board: TBoard;
    dic: array[0..500000] of string;
    dicMax: longint;
    pCur: smallint;
    pNo: smallint;
    players: array[0..3] of TPlayer;
    tmpTime: TCTime;
    beginTime: TCTime;
    initTime: TCTime;
    continuePass: smallint;
    hist: array[0..1001] of THistEntry;
    histCount: integer;
    tabing: smallint;
    tilesUsedUp: boolean;
    status: string;
    
//enterWord related
    putted: array[0..6] of TBoardGrid;
    puttedCount: smallint;
    dirx, typing, connected, firstRound: boolean;
    curx, cury: smallint;
    
//action related
    option: smallint;
    
//done related
    formedWord: array[0..7] of string;
    formedWordCount: smallint;
    usedPreSq: array[0..14,0..14] of boolean;
    
//mainMsg related
    page: array[0..4] of smallint;
    msgTmp: ansistring;
    tilesRemaining: array[0..26] of smallint;
    dicCkStr: array[0..4] of string;
    dicResult: array[0..4] of smallint;
    eventsLine: array[0..4] of integer;
    
    function toString(int:integer):string;
    begin
        str(int, toString);
    end;
        
    function add0(num: integer):string;
    begin
        str(num, add0);
        if num<10 then
            add0:='0'+add0;
    end;
    
    function toUpperCase(AChr: char):char;
    begin
        toUpperCase:=AChr;
        case AChr of
            'a'..'z': toUpperCase:=chr(ord(AChr)-32);
        end;
    end;
    
    function toUpperCaseString(aWord: string):string;
    var
        i: integer;
    begin
        toUpperCaseString:=aWord;
        for i:=1 to length(aWord) do
            toUpperCaseString[i]:=toUpperCase(aWord[i]);
    end;
    
    function toLowerCase(AChr: char):char;
    begin
        toLowerCase:=AChr;
        case AChr of
            'A'..'Z': toLowerCase:=chr(ord(AChr)+32);
        end;
    end;
    
    function calcTilesMark(player: TPlayer):integer;
    var
        i: smallint;
    begin
        calcTilesMark:=0;
        for i:=0 to 6 do
            if player.hand[i]<>' ' then
                if player.hand[i]<>'?' then
                    calcTilesMark:=calcTilesMark+tilesScore[ord(player.hand[i])-ord('A')]
                else                                                            
                    calcTilesMark:=calcTilesMark+0;
    end;
    
    function formTiles(player: TPlayer):string;
    var
        i: integer;
    begin
        formTiles:='';
        for i:=0 to 6 do
            if player.hand[i]<>' ' then
                formTiles:=formTiles+player.hand[i]+' '
            else
                formTiles:=formTiles+'/ ';
    end;
    
    function formTilesMark(player: TPlayer):string;
    var
        i: integer;
    begin
        formTilesMark:='';
        for i:=0 to 6 do
            if player.hand[i]<>' ' then
                if player.hand[i]='?' then           
                    formTilesMark:=formTilesMark+' 0'
                else
                    if tilesScore[ord(player.hand[i])-ord('A')]<10 then
                        formTilesMark:=formTilesMark+' '+toString(tilesScore[ord(player.hand[i])-ord('A')])
                    else
                        formTilesMark:=formTilesMark+' +'
            else
                formTilesMark:=formTilesMark+'  ';
    end;
    
    procedure countTiles(var tilesRemaining: array of smallint);
    var
        i: integer;
    begin
        for i:=0 to 26 do
            tilesRemaining[i]:=0;
        for i:=bagCount to 100 do
        begin
            if bag[i]<>'?' then
                tilesRemaining[ord(bag[i])-ord('A')]:=tilesRemaining[ord(bag[i])-ord('A')]+1
            else
                tilesRemaining[26]:=tilesRemaining[26]+1;
        end;
    end;
        
    function addSpace(input: string; kind: char; leng: integer):string;
    begin
        case kind of
            'p':
                while length(input)<leng do
                    input:=' '+input;
            's':
                while length(input)<leng do
                    input:=input+' ';
        end;
        addSpace:=input;
    end;
    
    function loadDic(path: string; var dic: array of string; var dicMax: longint):boolean;
    var
        f: text;
        i: longint;
        wholeDir, tmpDir: string;
        seperator: char;
        tmpPos, pos1: integer;
        
    begin
        for i:=0 to 500000 do
            dic[i]:='';
        dicMax:=0;
        wholeDir:=paramStr(0);
        tmpDir:=wholeDir;
        if OS then
            seperator:='\'
        else
            seperator:='/';
        pos1:=0;
        repeat
            tmpPos:=pos(seperator, tmpDir);
            if tmpPos<>0 then
            begin
                pos1:=tmpPos+pos1;
                tmpDir:=copy(tmpDir, tmpPos+1, length(tmpDir)-tmpPos);
            end;
        until tmpPos=0;
        path:=copy(wholeDir, 1, pos1)+path;
        i:=0;
        assign(f, path);
        reset(f);
        while not eof(f) do
        begin
            readln(f, dic[i]);
            i:=i+1;
        end;
        close(f);
        dicMax:=i-1;
        loadDic:=dicMax<>-1;
    end;
    
    function isValid(aWord: string):boolean;
    var
        lower, upper: longint;
        index: longint;
    begin
        isValid:=FALSE;
        if (length(aWord)<2) or (length(aWord)>15) then exit;
        aWord:=toUpperCaseString(aWord);
        lower:=0;
        upper:=dicMax;
        while lower<=upper do
        begin
            index:=(lower+upper) div 2;   
            if aWord=dic[index] then
            begin
                isValid:=TRUE;
                break;
            end;
            if aWord>dic[index] then lower:=index+1;
            if aWord<dic[index] then upper:=index-1;
        end;
    end;
    
    function getNow:TCTime;
    var
        hh, mm, ss, ms: word;
    begin
        getTime(hh, mm, ss, ms);
        getNow.h:=hh;
        getNow.m:=mm;
        getNow.s:=ss;
        getNow.ms:=ms;
        getNow.tms:=ms*10+ss*1000+mm*60000+hh*3600000;
    end;
    
    function formTime(aTime:TCTime):string;
    begin
        formTime:='';
        if aTime.h<>0 then
            formTime:=formTime+toString(aTime.h)+'h';
        if aTime.m<>0 then
            formTime:=formTime+toString(aTime.m)+'m';
        if aTime.s<>0 then
            formTime:=formTime+toString(aTime.s)+'s';
        //if aTime.ms<>0 then
        //    formTime:=formTime+toString(aTime.m)+'ms';
    end;
    
    procedure writeTime(aTime:TCTime);
    begin
        if aTime.h<>0 then
            write(aTime.h, 'h');
        if aTime.m<>0 then
            write(aTime.m, 'm');
        if aTime.s<>0 then
            write(aTime.m, 's');
        //if aTime.ms<>0 then
        //    write(aTime.m, 'ms');
        //write(aTime.h, 'h', aTime.m, 'm', aTime.s, 's', aTime.ms, 'ms');
    end;
    
    procedure writeSysTime;
    var
        now: TCTime;
    begin
        now:=getNow;
        write('SYSTEM TIME: ',add0(now.h), ':', add0(now.m), ':', add0(now.s), '; ');
    end;
    
    function stdTime(aTime:TCTime):TCTime;
    begin
        if aTime.tms=0 then
            aTime.tms:=aTime.ms+aTime.s*1000+aTime.m*60000+aTime.h*3600000;
        aTime.h:=aTime.tms div 3600000;
        aTime.m:=(aTime.tms div 60000) mod 60;
        aTime.s:=(aTime.tms div 1000) mod 60;
        aTime.ms:=aTime.tms mod 1000;
        stdTime:=aTime;
    end;

    function changeTime(changeKind: char; aTime: TCTime; objTime: int64):TCTime;
    begin
        changeTime:=aTime;
        case changeKind of
            '+': changeTime.tms:=changeTime.tms+objTime;
            '-': changeTime.tms:=changeTime.tms-objTime;
            '*': changeTime.tms:=changeTime.tms*objTime;
            '/': changeTime.tms:=changeTime.tms div objTime;
        end;
        changeTime:=stdTime(changeTime);
    end;

    procedure swapChr(var x, y: char);
    var
        temp: char;
    begin
        temp:=x;
        x:=y;
        y:=temp;
    end;
    
    procedure sort(var chrs: array of char);
    var
        i, j: smallint;
    begin
        for i:=6 downto 0 do
            for j:=0 to i-1 do
                if chrs[j]>chrs[j+1] then
                    swapChr(chrs[j], chrs[j+1]);
    end;
    
    procedure sortBag(var chrs: array of char);
    var
        i, j: smallint;
    begin
        for i:=high(chrs)-1 downto 0 do
            for j:=0 to i-1 do
                if chrs[j]>chrs[j+1] then
                    swapChr(chrs[j], chrs[j+1]);
    end;
    
    procedure washBag(var aBag: string);
    var
        i: byte;
    begin
        for i:=1 to length(aBag) do
        begin
            swapChr(aBag[i], aBag[random(i)+1]);
        end
    end;
    
    procedure drawTiles(bag: string; var bagCount: smallint; var hand: array of char);
    var
        i: byte;
    begin
        for i:=0 to 6 do
            if hand[i]=' ' then
            begin
                if bagCount>100 then
                    exit;
                hand[i]:=bag[bagCount];
                bagCount:=bagCount+1;
            end;
        
    end;
    
    function saveGame(path: string):boolean;
    var
        f: text;
        i, j: smallint;
        wholeDir, tmpDir: string;
        seperator: char;
        tmpPos, pos1: integer;
        
    begin
        wholeDir:=paramStr(0);
        tmpDir:=wholeDir;
        if pos('/', wholeDir)<>0 then
            seperator:='/'
        else
            seperator:='\';
        OS:=seperator='\';
        pos1:=0;
        repeat
            tmpPos:=pos(seperator, tmpDir);
            if tmpPos<>0 then
            begin
                pos1:=tmpPos+pos1;
                tmpDir:=copy(tmpDir, tmpPos+1, length(tmpDir)-tmpPos);
            end;
        until tmpPos=0;
        path:=copy(wholeDir, 1, pos1)+path;
        assign(f, path);
        rewrite(f);
        writeln(f, bag);
        writeln(f, bagCount);
        for i:=0 to 14 do
            writeln(f, board[i]);
        writeln(f, pCur);
        writeln(f, pNo);
        for i:=0 to pNo-1 do
            with players[i] do
            begin
                writeln(f, id);
                writeln(f, name1);
                writeln(f, name2);
                for j:=0 to 6 do
                    write(f, hand[j]);
                writeln(f);
                writeln(f, mark);
                writeln(f, time.h);
                writeln(f, time.m);
                writeln(f, time.s);
                writeln(f, time.ms);
                writeln(f, time.tms);
                for j:=0 to 3 do
                    writeln(f, icon[j]);
                writeln(f, timeStore.h);
                writeln(f, timeStore.m);
                writeln(f, timeStore.s);
                writeln(f, timeStore.ms);
                writeln(f, timeStore.tms);
                if timeIsUp then
                    writeln(f, '1')
                else
                    writeln(f, '0');
            end;
        writeln(f, continuePass);
        writeln(f, tabing);
        writeln(f, option);
        for i:=0 to 14 do
            for j:=0 to 14 do
                if usedPreSq[i, j] then
                    writeln(f, '1')
                else
                    writeln(f, '0');
        writeln(f);
        for i:=0 to pNo-1 do
        begin
            writeln(f, page[i]);
            writeln(f, dicCkStr[i]);
            writeln(f, dicResult[i]);
            writeln(f, eventsLine[i]);
        end;
        close(f);
        saveGame:=TRUE;
    end;
    
    function loadGame(path: string):boolean;
    var
        f: text;
        i, j: smallint;
        wholeDir, tmpDir: string;
        seperator: char;
        tmpPos, pos1: integer;
        tmpChar: char;
        
    begin
        wholeDir:=paramStr(0);
        tmpDir:=wholeDir;
        if pos('/', wholeDir)<>0 then
            seperator:='/'
        else
            seperator:='\';
        OS:=seperator='\';
        pos1:=0;
        repeat
            tmpPos:=pos(seperator, tmpDir);
            if tmpPos<>0 then
            begin
                pos1:=tmpPos+pos1;
                tmpDir:=copy(tmpDir, tmpPos+1, length(tmpDir)-tmpPos);
            end;
        until tmpPos=0;
        path:=copy(wholeDir, 1, pos1)+path;
        assign(f, path);
        reset(f);
        readln(f, bag);
        readln(f, bagCount);
        for i:=0 to 14 do
            readln(f, board[i]);
        readln(f, pCur);
        readln(f, pNo);
        for i:=0 to pNo-1 do
            with players[i] do
            begin
                readln(f, id);
                readln(f, name1);
                readln(f, name2);
                for j:=0 to 6 do
                    read(f, hand[j]);
                readln(f);
                readln(f, mark);
                readln(f, time.h);
                readln(f, time.m);
                readln(f, time.s);
                readln(f, time.ms);
                readln(f, time.tms);
                for j:=0 to 3 do
                    readln(f, icon[j]);
                readln(f, timeStore.h);
                readln(f, timeStore.m);
                readln(f, timeStore.s);
                readln(f, timeStore.ms);
                readln(f, timeStore.tms);
                readln(f, tmpChar);
                timeIsUp:=tmpChar='1';
            end;
        readln(f, continuePass);
        readln(f, tabing);
        readln(f, option);
        for i:=0 to 14 do
            for j:=0 to 14 do
            begin
                read(f, tmpChar);
                usedPreSq[i, j]:=tmpChar='1';
            end;
        readln(f);
        for i:=0 to pNo-1 do
        begin
            readln(f, page[i]);
            readln(f, dicCkStr[i]);
            readln(f, dicResult[i]);
            readln(f, eventsLine[i]);
        end;
        close(f);
        loadGame:=TRUE;
    end;
    
    procedure outputPlayerProfileSingle(pCur: byte; player: TPlayer; current: boolean);
    const
        thisT=1;
        thisL=34;
    var
        j: byte;
        
        function outputMMSS(aTime:TCTime):string;
        begin
            outputMMSS:=add0(aTime.h*60+aTime.m)+':'+add0(aTime.s);
        end;
        
        
    begin
        if current then
            textcolor(yellow);
        with player do
            for j:=0 to 5 do
            begin
                gotoxy(thisL, thisT+pCur*6+j);
                case j of
                    0: write('/-------------\');
                    1: write('|', icon[0], ' ', name1, '|':8-length(name1));
                    2: write('|', icon[1], ' ', name2, '|':8-length(name2));
                    3:
                    if mark=0 then
                        write('|', icon[2], ' 0      |')
                    else
                        write('|', icon[2], ' ', mark, '|':7-trunc(ln(mark) / ln(10)));
                    4: write('|', icon[3], ' ', outputMMSS(time), '|':8-length(outputMMSS(time)));
                    5: write('\-------------/');
                end;
            end;  
        textcolor(7);
        gotoxy(80, 24);
    end;
    
    procedure outputPlayerProfile(pNo: byte; players:array of TPlayer);
    var
        i: byte;
        bool: boolean;
    begin
        for i:=0 to pNo-1 do
        begin
            bool:=i=pCur;
            outputPlayerProfileSingle(i, players[i], bool);
        end;
        gotoxy(80, 24);
    end;
    
    procedure outputMainMsg(option:byte; msg: ansistring);
    const
        thisT=1;
        thisL=1;
        boxT=4;
        boxL=2;
        boxW=30;
        boxH=20;
        tabColor=blue;
    var
        skip: boolean;
        txtcolor, bgcolor: smallint;
        thisWord: string;
        x, y: smallint;
        readcolor, readSpecial: boolean;
        i: integer;
        
        function hex2int(c: char):smallint;
        begin
            hex2int:=0;
            case c of
                '0'..'9': hex2int:=ord(c)-ord('0');
                'A'..'F': hex2int:=ord(c)-55;
                'a'..'f': hex2int:=ord(c)-87;
            end;
        end;
        
        procedure writeMsg(var x, y: smallint; fg, bg: smallint; msg: string);
        begin
            if (x+length(msg))>boxW then
            begin
                y:=y+1;
                x:=0;
            end;
            if y>boxH-1 then
                exit;
            gotoxy(x+boxL, y+boxT);
            textcolor(fg);
            textbackground(bg);
            write(msg);
            {gotoxy(50, 1);
            write(msg+'     ');
            readln;}
            x:=x+length(msg);
        end;
        
        procedure writeMsgOutline(option: byte);
        var
            i: byte;
        //const
            //tab: array[0..3] of string =('EVENTS', 'DICTIOANRY', 'NOTES', 'TILES');
        begin
            textcolor(7);
            for i:=0 to 23 do
            begin
                gotoxy(thisL, thisT+i);
                case i of
                    0    : write('/------------------------------\');
                    1    :
                    begin
                        write('|');
                        if tabing=2 then
                            case option of
                                0:
                                begin
                                    textbackground(tabColor);
                                    write('DICTIONARY     ');
                                    textbackground(baseBackground);
                                    write('|TILES         ');
                                end;
                                1:
                                begin
                                    textbackground(baseBackground);
                                    write('DICTIONARY     |');
                                    textbackground(tabColor);
                                    write('TILES         ');
                                    textbackground(baseBackground);
                                end;
                            else
                                textbackground(baseBackground);
                                write('DICTIONARY     |TILES         ');
                            end
                        else
                        begin
                            textbackground(baseBackground);
                            write('DICTIONARY     |TILES         ');
                        end;
                        write('|');
                    end;
                    2    :
                    begin
                        write('|');
                        case option of
                            0: write('               +--------------');
                            1: write('---------------+              ');
                        else
                            write('------------------------------');
                        end;
                        write('|');
                    end;
                    3..22: write('|                              |');
                    23   : write('\------------------------------/');
                end;
            end;
        end;
        
    begin
        writeMsgOutline(option);
        msg:=msg+' ';
        skip:=FALSE;
        txtcolor:=7;
        bgcolor:=0;
        thisWord:='';
        x:=0;
        y:=0;
        readcolor:=FALSE;
        readSpecial:=FALSE;
        for i:=1 to length(msg) do
        begin
            if skip then
            begin
                skip:=FALSE;
                continue;
            end;
            if readcolor then
            begin
                skip:=TRUE;
                writeMsg(x, y, txtcolor, bgcolor, thisWord);
                thisWord:='';
                if not(msg[i] in ['x','X']) then
                    txtcolor:=hex2Int(msg[i]);
                if not(msg[i+1] in ['x','X']) then
                    bgcolor:=hex2Int(msg[i+1]);
                readcolor:=FALSE;
                continue;
            end;
            if readSpecial then
            begin
                case msg[i] of
                    'n':
                    begin
                        writeMsg(x, y, txtcolor, bgcolor, thisWord);
                        thisWord:='';
                        y:=y+1;
                        x:=0;
                    end;
                    '\': thisWord:=thisWord+'\';
                end;
                readSpecial:=FALSE;
                continue;
            end;
            if (msg[i]=' ') then
            begin
                writeMsg(x, y, txtcolor, bgcolor, thisWord);
                if i<>length(msg) then
                begin
                    writeMsg(x, y, txtcolor, bgcolor, ' ');
                end;
                thisWord:='';
            end
            else
            begin
                case msg[i] of
                    '`':
                        readcolor:=TRUE;
                    '\':
                        readSpecial:=TRUE;
                else
                    thisWord:=thisWord+msg[i];
                end;
            end;
        end;
        gotoxy(80, 24);
    end;
    
    procedure changeColorByGrid(x, y: smallint);
    begin
        case boardPreSq[x-7, y-7] of
            0: textcolor(8);
            1: textcolor(11);
            2: textcolor(9);
            3: textcolor(13);
            4: textcolor(12);
        else
            textcolor(7);
        end;
        if board[y, x]<>' ' then
            textcolor(15);
    end;
    
    procedure outputPuttedTiles();
    const
        thisL=50;
        thisT=2;
    var
        i: integer;
    begin
        textcolor(yellow);
        for i:=0 to puttedCount-1 do
        begin
            gotoxy(putted[i].x*2+thisL, putted[i].y+thisT);
            if putted[i].s then
                write(toLowerCase(putted[i].c))
            else
                write(putted[i].c);
            write(' ');
        end;
        textcolor(7);
    end;
    
    procedure outputBoardGrid(aBoard:TBoard; x, y: smallint);
    const
        thisT=2;
        thisL=50;
    begin
        gotoxy(thisL+x*2, thisT+y);
        changeColorByGrid(y, x);
        if aBoard[x,y]=' ' then
            write('[]')
        else
            write(aBoard[x,y],' ');
        textcolor(7);
        gotoxy(80, 24);
    end;
    
    procedure outputBoard(aBoard:TBoard);
    const
        thisT=2;
        thisL=50;
    var
        i, j: smallint;
    begin
        for i:=0 to 14 do
            for j:=0 to 14 do
                outputBoardGrid(aBoard, i, j);
        textcolor(7);
        gotoxy(80, 24);
    end;
    
    procedure outputWords(var words: array of char);
    const
        thisT=19;
        thisL=52;
        space=4;
    var
        i: smallint;
        tmp: smallint;
    begin
        textcolor(7);
        for i:=0 to 6 do
        begin
            if words[i]=' ' then
            begin
                gotoxy(thisL+i*space-1, thisT-1);
                write('    ');
                gotoxy(thisL+i*space-1, thisT);
                write('    ');
                gotoxy(thisL+i*space+1 -2, thisT+1);
                write('    ');
            end
            else
            begin
                gotoxy(thisL+i*space-1, thisT-1);
                write('+--+');
                gotoxy(thisL+i*space-1, thisT);
                write('|',words[i],' |');
                gotoxy(thisL+i*space+1 -2, thisT+1);
                if words[i]<>'?' then
                    tmp:=ord(words[i])-ord('A')
                else
                    tmp:=26;
                if tilesScore[tmp]<10 then
                    write('+--',tilesScore[tmp],' ')
                else
                    write('+-',tilesScore[tmp],' ');
            end;
        end;
        gotoxy(80, 24);
    end;
    
    procedure outputActions(option: smallint);
    const
        sortT=22;
        sortL=49;
        forfeitT=24;
        forfeitL=49;
        cmd: array[0..5] of string=(' [SORT] ', ' [SHUFFLE] ', ' [TAKE BACK] ',
                                    ' [FORFEIT] ', ' [PASS] ', ' [EXCHANGE] ');
{        cmd: array[0..6] of string=(' SORT ', ' SHUFFLE ', ' TAKE BACK ',
                                    ' FORFEIT ', ' PASS ', ' EXCHANGE ', ' DONE! ');}
    var
        i: smallint;
    begin
        gotoxy(sortL,sortT);
        for i:=0 to 2 do
        begin
            if option=i then
                textbackground(4);
            write(cmd[i]);
            if option=i then
                textbackground(0);
        end;
        gotoxy(forfeitL,forfeitT);
        for i:=3 to 5 do
        begin
            if option=i then
                textbackground(4);
            write(cmd[i]);
            if option=i then
                textbackground(0);
        end;
        gotoxy(80, 24);
    end;
    
    procedure outputStatus;
    begin
        if not OS then
            exit;
        gotoxy(80, 24);
            //for linux which only 24 lines
        gotoxy(1, 25);
        write('                                                                               ');
        gotoxy(1, 25);
        textcolor(10);
        writeSysTime;
        write('Status: ', status);
        textcolor(7);
    end;

    procedure outputWinningMsg();
    const
        thisW=60;
        thisL=(80-thisW) div 2;
    var
        thisT, thisH: smallint;
        i, j: smallint;
        highWord: array[0..3] of string;
        highWordScore: array[0..3] of integer;
        finalScore: array[0..3] of integer;
        bonusOrPenalty: array[0..3] of char;
        bonusOrPenaltyNumber: array[0..3] of integer;
        bagString: string;
        highestScore: integer;
        
        function formBagStringInOrder(tilesRemaining: array of smallint):string;
        var
            i: smallint;
        begin
            formBagStringInOrder:='';
            for i:=0 to 25 do
                while tilesRemaining[i]>0 do
                begin
                    formBagStringInOrder:=formBagStringInOrder+chr(ord('A')+i);
                    tilesRemaining[i]:=tilesRemaining[i]-1;
                end;
            while tilesRemaining[26]>0 do
            begin
                formBagStringInOrder:=formBagStringInOrder+'?';
                tilesRemaining[26]:=tilesRemaining[26]-1;
            end;
        end;
        
        procedure outputLS;
        begin
            textcolor(yellow);
            write('------------------------------------------------------------');
            textcolor(7);
        end;
        
    begin
        //textcolor(yellow);
        highestScore:=-9999;
        for i:=0 to 3 do
        begin
            highWord[i]:='';
            highWordScore[i]:=0;
        end;
        for i:=0 to histCount do
            with hist[i] do
                if action='D' then
                    if highWordScore[uid]<mark then
                    begin
                        highWordScore[uid]:=mark;
                        highWord[uid]:=highestFormedWord;
                    end;
        for i:=0 to pNo-1 do
        begin
            if tilesUsedUp and (i=((pCur+pNo-1) mod pNo))then
                bonusOrPenalty[i]:='+'
            else
                bonusOrPenalty[i]:='-';
            calcTilesMark(players[i]);
            if bonusOrPenalty[i]='+' then
            begin
                bonusOrPenaltyNumber[i]:=0;
                for j:=0 to pNo-1 do
                    if i<>j then
                        bonusOrPenaltyNumber[i]:=bonusOrPenaltyNumber[i]+calcTilesMark(players[j]);
            end
            else
                bonusOrPenaltyNumber[i]:=-calcTilesMark(players[i]);
            finalScore[i]:=players[i].mark+bonusOrPenaltyNumber[i];
            if finalScore[i]>highestScore then
                highestScore:=finalScore[i];
        end;
        for i:=0 to pNo-1 do
            players[i].isWinning:=finalScore[i]>=highestScore;
                    
        thisH:=3+4*pNo+1;
        if bagCount<40 then
            thisH:=thisH+1;
        thisT:=(26-thisH) div 2;
        textcolor(yellow);
        gotoxy(thisL-1, thisT-1);
        write('/------------------------------------------------------------\');
        gotoxy(thisL-1, thisT);
        write('|Icon  Player  Marks TimeLeft UnplayedTiles  HighestWord     |');
        gotoxy(thisL-1, thisT+1);
        write('|------------------------------------------------------------|');
        for i:=2 to thisH do
        begin
            gotoxy(thisL-1, thisT+i);
            write('|                                                            |');
        end;
        gotoxy(thisL-1, thisT+1+thisH);
        write('\------------------------------------------------------------/');
        textcolor(7);
        for i:=0 to pNo-1 do
        begin
            //if players[i].isWinning then
            //    textcolor(lightgreen)
            //else
            //    textcolor(8);
            for j:=0 to 3 do
            begin
                gotoxy(thisL, thisT+2+i*4+j);
                write(players[i].icon[j], ' ');
                case j of
                    0: writeln(addSpace(players[i].name1, 's', 7), ' ', addSpace(toString(players[i].mark), 'p', 5), ' ', addSpace(formTime(players[i].time), 's', 9), formTiles(players[i]), ' ', addSpace(highWord[i], 's', 16));
                    1: writeln(addSpace(players[i].name2, 's', 7), ' ', bonusOrPenalty[i], addSpace(toString(abs(bonusOrPenaltyNumber[i])), 'p', 4), '          ', formTilesMark(players[i]), ' ', addSpace(toString(highWordScore[i])+' Marks', 's', 16));
                    2: writeln('        =', addSpace(toString(finalScore[i]), 'p', 4));
                    3:
                    begin
                        if players[i].isWinning then
                        begin
                            textcolor(lightgreen);
                            write('WIN ');
                        end
                        else
                        begin
                            textcolor(lightred);
                            write('LOSE');
                        end;
                        if pNo=2 then
                            write('         Spread: ', finalScore[i]-finalScore[1-i]);
                    end;
                end;
            end;
            //gotoxy(thisL, thisT+2+i*5+4);
            //outputLS;
            textcolor(7);
        end;
        gotoxy(thisL, thisT+2+pNo*4);
        outputLS;
        countTiles(tilesRemaining);
        bagString:=formBagStringInOrder(tilesRemaining);
        gotoxy(thisL, thisT+2+pNo*4+1);
        write('Tiles Left in bag: (', length(bagString), ')');
        gotoxy(thisL, thisT+3+pNo*4+1);
        if bagCount>40 then
        begin
            write(addSpace(copy(bagString, 1, 60-length(bagString)+1), 's', 60));
        end
        else
        begin
            write(addSpace(copy(bagString, 1, 60) , 's', 60));
            gotoxy(thisL, thisT+4+pNo*4+1);
            write(addSpace(copy(bagString, 61, length(bagString)-60), 's', 60));
        end;
        //textcolor(white);
    end;
    
    function updateTime(pCur: smallint): boolean;
    begin
        outputStatus;
        updateTime:=TRUE;
        textcolor(7);
        tmpTime.tms:=players[pCur].timeStore.tms-changeTime('-', getNow, beginTime.tms).tms;
        if tmpTime.tms > -1 then
            if players[pCur].time.tms<>stdTime(tmpTime).tms then
            begin
                players[pCur].time:=stdTime(tmpTime);
                outputPlayerProfileSingle(pCur, players[pCur], TRUE);
            end
            else
        else
        begin
            players[pCur].time.tms:=-1;
            players[pCur].time:=stdTime(players[pCur].time);
            drawTiles(bag, bagCount, players[pCur].hand);
            outputPlayerProfileSingle(pCur, players[pCur], TRUE);
            updateTime:=FALSE;
        end;
        gotoxy(80, 24);
    end;
    
    procedure menu(option: smallint);
    const
        txt: array[0..4] of string = ('Continue Game', 'Start Game', 'View Game', 'Help', 'Exit');
    var
        i, j: smallint;
        tmp: string;
        key: char;
        tmpFg: smallint;
        
        //preStartOption 'global' var
            options: array[0..3] of smallint;
            tmpStr: string;
            tmpName: array[1..2] of string;
            tmpIcon: TIcon;
            curx, cury: smallint;
            tabs: smallint;
            iconSet: smallint;
        
        procedure outputTitle;
        begin
            clrscr;
            textcolor(yellow);
            writeln('      _/_/_/   _/_/_/ _/_/_/     _/_/   _/_/_/   _/_/_/   _/       _/_/_/_/   ');
            writeln('   _/       _/       _/    _/ _/    _/ _/    _/ _/    _/ _/       _/          ');
            writeln('    _/_/   _/       _/_/_/   _/_/_/_/ _/_/_/   _/_/_/   _/       _/_/_/       ');
            writeln('       _/ _/       _/    _/ _/    _/ _/    _/ _/    _/ _/       _/            ');
            writeln('_/_/_/     _/_/_/ _/    _/ _/    _/ _/_/_/   _/_/_/   _/_/_/_/ _/_/_/_/       ');
            textcolor(7);
            writeln;
        end;
    
        procedure outputMiddle(data: string; fg, bg: smallint);
        var
            i: integer;
        begin
            for i:=0 to (80-length(data)) div 2 do
                write(' ');
            if fg<>-1 then
                textcolor(fg);
            if bg<>-1 then
                textbackground(bg);
            write(data);
            for i:=(80-length(data)) div 2+length(data) to 70 do
                write(' ');
            writeln;
        end;
        
        procedure preStartOption(option: smallint; optionPre: integer);
        const
            opt1: array[0..2] of string = ('2', '3', '4');
            opt2: array[0..4] of string = ('10', '15', '20', '25', '30');
            opt3: array[0..3] of string = ('+3pts', '-5pts', 'double', 'void');
            opt4: array[0..1] of string = ('CSW07', 'CSW12');
            thisT=9;
            thisL=26;
            off: array[1..2] of smallint = (0, 1);
        var
            i, j: smallint;
            key: char;
            leftarrow, rightarrow: char;

            procedure outputLineX(line: smallint);
            begin
                case line of
                    0: outputMiddle('Player No: '+leftarrow+' '+opt1[options[0]]+' '+rightarrow, -1, -1);
                    1: outputMiddle('Time limit per player: '+leftarrow+' '+opt2[options[1]]+' '+rightarrow, -1, -1);
                    2: outputMiddle('Challenge type: '+leftarrow+' '+opt3[options[2]]+' '+rightarrow, -1, -1);
                    3: outputMiddle('Dictionay version: '+leftarrow+' '+opt4[options[3]]+' '+rightarrow, -1, -1);
                end;
            end;
            
            procedure changeLineX(old, newOne: smallint);
            begin
                gotoxy(1, 7+old);
                textcolor(7);
                outputLineX(old);
                gotoxy(1, 7+newOne);
                textcolor(yellow);
                outputLineX(newOne);
            end;
            
            
        begin
            options[0]:=optionPre div 1000;
            optionPre:=optionPre mod 1000;
            options[1]:=optionPre div 100;
            optionPre:=optionPre mod 100;
            options[2]:=optionPre div 10;
            options[3]:=optionPre mod 10;
            outputTitle;
            for i:=0 to 3 do
            begin
                if not OS then
                begin
                    leftarrow:='<';
                    rightarrow:='>';
                end
                else
                begin
                    leftarrow:=#17;
                    rightarrow:=#16;
                end;
                if option=i then
                    textcolor(yellow)
                else
                    textcolor(7);
                outputLineX(i);
                textcolor(7);
            end;
            writeln;
            outputMiddle('Press LEFT/RIGHT to change the option.', -1, -1);
            outputMiddle('Press ENTER to create players'' profiles.', -1, -1);
            repeat
                key:=readkey;
                case key of 
                    #0:
                    begin
                        key:=readkey;
                        case key of
                            #72:
                            begin
                                changeLineX(option, (option+3) mod 4);
                                option:=(option+3) mod 4;
                            end;
                            #80:
                            begin
                                changeLineX(option, (option+1) mod 4);
                                option:=(option+1) mod 4;
                            end;
                            #75:
                            case option of
                                0:
                                begin
                                    options[0]:=(options[0]+2) mod 3;
                                    changeLineX(option, option);
                                end;
                                1:
                                begin
                                    options[1]:=(options[1]+4) mod 5;
                                    changeLineX(option, option);
                                end;
                                2:
                                begin
                                    options[2]:=(options[2]+3) mod 4;
                                    changeLineX(option, option);
                                end;
                                3:
                                begin
                                    options[3]:=(options[3]+1) mod 2;
                                    changeLineX(option, option);
                                end;
                            end;
                            #77:
                            case option of
                                0:
                                begin
                                    options[0]:=(options[0]+1) mod 3;
                                    changeLineX(option, option);
                                end;
                                1:
                                begin
                                    options[1]:=(options[1]+1) mod 5;
                                    changeLineX(option, option);
                                end;
                                2:
                                begin
                                    options[2]:=(options[2]+1) mod 4;
                                    changeLineX(option, option);
                                end;
                                3:
                                begin
                                    options[3]:=(options[3]+1) mod 2;
                                    changeLineX(option, option);
                                end;
                            end;
                        end;
                        continue;
                    end;
                    #13:
                    begin
                        pNo:=options[0]+2;
                        for i:=0 to pNo-1 do
                        begin
                            outputTitle;
                            str(i, tmpStr);
                            outputMiddle('PlayerID '+tmpStr+'         Template', -1, -1);
                            outputMiddle('/-------------\   /-------------\', -1, -1);
                            outputMiddle('|             |   |  o   Richard|', -1, -1);
                            outputMiddle('|             |   |--+-- Fat    |', -1, -1);
                            outputMiddle('|      MARK   |   |  |   312    |', -1, -1);
                            outputMiddle('|      TIME   |   | / \  15:26  |', -1, -1);
                            outputMiddle('\-------------/   \-------------/', -1, -1);
                            writeln;
                            outputMiddle('Default Icon: '+leftarrow+' 0 '+rightarrow, -1, -1);
                            outputMiddle(' [DONE] ', -1, -1);
                            writeln;
                            outputMiddle('Press TAB to change edit field.', -1, -1);
                            str(i, tmpStr);
                            tabs:=0;
                            curx:=0;
                            cury:=0;
                            tmpName[1]:='       ';
                            tmpName[2]:='       ';
                            iconSet:=0;
                            for j:=0 to 3 do
                                tmpIcon[j]:='     ';
                            repeat
                                case tabs of
                                    0:
                                    begin
                                        gotoxy(thisL+curx,thisT+cury);
                                        key:=readkey;
                                        case key of
                                            #0:
                                            begin
                                                key:=readkey;
                                                case key of
                                                    #72: if cury>0 then cury:=cury-1;
                                                    #75: if curx>0 then curx:=curx-1;
                                                    #77: if curx<4 then curx:=curx+1;
                                                    #80: if cury<3 then cury:=cury+1;
                                                    #83:
                                                    begin
                                                        tmpIcon[cury][curx+1]:=' ';
                                                        write(' ');
                                                        curx:=curx-1;
                                                        if curx<0 then
                                                            if cury>0 then
                                                            begin
                                                                curx:=4;
                                                                cury:=cury-1;
                                                            end
                                                            else
                                                            begin
                                                                curx:=4;
                                                                cury:=3;
                                                            end;
                                                        gotoxy(thisL+curx, thisT+cury);
                                                    end;
                                                else
                                                    continue;
                                                end;
                                                gotoxy(thisL+curx, thisT+cury);
                                            end;
                                            #8:
                                            begin
                                                curx:=curx-1;
                                                if curx<0 then
                                                    if cury>0 then
                                                    begin
                                                        curx:=4;
                                                        cury:=cury-1;
                                                    end
                                                    else
                                                    begin
                                                        curx:=4;
                                                        cury:=3;
                                                    end;
                                                gotoxy(thisL+curx, thisT+cury);
                                                tmpIcon[cury][curx+1]:=' ';
                                                write(' ');
                                                iconSet:=0;
                                                gotoxy(1, thisT+6);
                                                str(iconSet, tmpStr);
                                                outputMiddle('Default Icon: '+leftarrow+' '+tmpStr+' '+rightarrow, -1, -1);
                                            end;
                                            #13:
                                            begin
                                                curx:=0;
                                                cury:=(cury+1) mod 4;
                                            end;
                                            #9:
                                            begin
                                                tabs:=(tabs+1) mod 5;
                                                curx:=0;
                                                cury:=0;
                                            end;
                                        else
                                            tmpIcon[cury][curx+1]:=key;
                                            write(key);
                                            curx:=curx+1;
                                            if curx>4 then
                                                if cury<3 then
                                                begin
                                                    curx:=0;
                                                    cury:=cury+1;
                                                end
                                                else
                                                begin
                                                    curx:=0;
                                                    cury:=0;
                                                end;
                                            iconSet:=0;
                                            gotoxy(1, thisT+6);
                                            str(iconSet, tmpStr);
                                            outputMiddle('Default Icon: '+leftarrow+' '+tmpStr+' '+rightarrow, -1, -1);
                                        end;
                                    end;
                                    1, 2:
                                    begin
                                        gotoxy(thisL+curx+6,thisT+cury+off[tabs]);
                                        key:=readkey;
                                        case key of
                                            #0:
                                            begin
                                                key:=readkey;
                                                case key of
                                                    #75: if curx>0 then curx:=curx-1;
                                                    #77: if curx<6 then curx:=curx+1;
                                                    #83:
                                                    begin
                                                        tmpName[tabs][curx+1]:=' ';
                                                        write(' ');
                                                        curx:=curx-1;
                                                        if curx<0 then
                                                            curx:=0;
                                                        gotoxy(thisL+curx+6, thisT+cury+off[tabs]);
                                                    end;
                                                else
                                                    continue;
                                                end;
                                                gotoxy(thisL+curx+6, thisT+cury+off[tabs]);
                                            end;
                                            #8:
                                            begin
                                                if tmpName[tabs][curx+1]=' ' then
                                                begin
                                                    curx:=curx-1;
                                                    if curx<0 then
                                                        curx:=0;
                                                    gotoxy(thisL+curx+6, thisT+cury+off[tabs]);
                                                    tmpName[tabs][curx+1]:=' ';
                                                    write(' ');
                                                end
                                                else
                                                begin
                                                    gotoxy(thisL+curx+6, thisT+cury+off[tabs]);
                                                    tmpName[tabs][curx+1]:=' ';
                                                    write(' ');
                                                end;
                                            end;
                                            #9:
                                            begin
                                                tabs:=(tabs+1) mod 5;
                                                curx:=0;
                                                cury:=0;
                                            end;
                                            #13:;
                                        else
                                            tmpName[tabs][curx+1]:=key;
                                            write(key);
                                            curx:=curx+1;
                                            if curx>6 then
                                                curx:=6;
                                        end;
                                    end;
                                    3:
                                    begin
                                        gotoxy(1, thisT+6);
                                        textcolor(yellow);
                                        str(iconSet, tmpStr);
                                        outputMiddle('Default Icon: '+leftarrow+' '+tmpStr+' '+rightarrow, -1, -1);
                                        repeat
                                            key:=readkey;
                                            case key of
                                                #0:
                                                begin
                                                    key:=readkey;
                                                    case key of
                                                        #75: iconSet:=(iconSet+4) mod 5;
                                                        #77: iconSet:=(iconSet+1) mod 5;
                                                    else
                                                        continue;
                                                    end;
                                                    gotoxy(1, thisT+6);
                                                    textcolor(yellow);
                                                    str(iconSet, tmpStr);
                                                    outputMiddle('Default Icon: '+leftarrow+' '+tmpStr+' '+rightarrow, -1, -1);
                                                    textcolor(7);
                                                    for j:=0 to 3 do
                                                    begin
                                                        gotoxy(thisL+curx,thisT+cury+j);
                                                        if iconSet=0 then
                                                            write(tmpIcon[j])
                                                        else
                                                            write(defaultIcon[iconSet-1][j]);
                                                    end;
                                                end;
                                                #9, #13:
                                                begin
                                                    tabs:=(tabs+1) mod 5;
                                                    gotoxy(1, thisT+6);
                                                    textcolor(7);
                                                    str(iconSet, tmpStr);
                                                    outputMiddle('Default Icon: '+leftarrow+' '+tmpStr+' '+rightarrow, -1, -1);
                                                    if iconSet<>0 then
                                                        tmpIcon:=defaultIcon[iconSet-1];
                                                    for j:=0 to 3 do
                                                    begin
                                                        gotoxy(thisL+curx,thisT+cury+j);
                                                        write(tmpIcon[j]);
                                                    end;
                                                    break;
                                                end;
                                            end;
                                        until false;
                                    end;
                                    4:
                                    begin
                                        textcolor(yellow);
                                        gotoxy(thisL+12, thisT+6+1);
                                        writeln(' [DONE] ');
                                        textcolor(7);
                                        key:=readkey;
                                        case key of
                                            #13:
                                            begin
                                                while length(tmpName[1])<7 do
                                                    tmpName[1]:=tmpName[1]+' ';
                                                while length(tmpName[2])<7 do
                                                    tmpName[2]:=tmpName[2]+' ';
                                                for j:=0 to 3 do
                                                    while length(tmpIcon[j])<5 do
                                                        tmpIcon[j]:=tmpIcon[j]+' ';
                                                with players[i] do
                                                begin
                                                    timeIsUp:=FALSE;
                                                    name1:=tmpName[1];
                                                    name2:=tmpName[2];
                                                    icon:=tmpIcon;
                                                    mark:=0;
                                                    id:=i;
                                                    val(opt2[options[1]], time.tms);
                                                    time.tms:=60000*time.tms;
                                                    timeStore.tms:=time.tms;
                                                    time:=stdTime(time);
                                                    isWinning:=FALSE;
                                                    for j:=0 to 6 do
                                                        hand[j]:=' ';
                                                    drawTiles(bag, bagCount, hand);
                                                end;
                                                break;
                                            end;
                                            #9:
                                            begin
                                                tabs:=(tabs+1) mod 5;
                                                textcolor(7);
                                                gotoxy(thisL+12, thisT+7);
                                                writeln(' [DONE] ');
                                                curx:=0;
                                                cury:=0;
                                            end;
                                        end;
                                    end;
                                end;
                            until false;
                        end;
                        writeln('Loading dictionary...');
                        case options[3] of
                            0: loadDic('CSW07.txt', dic, dicMax);
                            1: loadDic('CSW12.txt', dic, dicMax);
                        end;
                        exit;
                    end;
                    else
                        continue;
                end;
            until false;            
        end;
        
    begin
        if option>-1 then
        begin
            outputTitle;
            outputMiddle('MENU', -1, -1);
            writeln;
            for i:=0 to 4 do
            begin
                if i=option then
                begin
                    tmp:='>> ';
                    tmpFg:=yellow;
                end
                else
                begin
                    tmp:='';
                    tmpFg:=-1;
                end;
                outputMiddle(tmp+txt[i], tmpFg, -1);
                if i=option then
                    textcolor(7);
                writeln;
            end;
        end
        else
        begin
            option:=abs(option)-1;
            gotoxy(1, 9+option*2);
            outputMiddle('>> '+txt[option], yellow, -1);
        end;
        key:=readkey;
        case key of
            #0:
            begin
                key:=readkey;
                case key of
                    #72:
                    begin
                        gotoxy(1, 9+option*2);
                        outputMiddle(txt[option], 7, -1);
                        option:=-(option+4) mod 5 -1;
                    end;
                    #80:
                    begin
                        gotoxy(1, 9+option*2);
                        outputMiddle(txt[option], 7, -1);
                        option:=-(option+6) mod 5 -1;
                    end
                else
                    option:=-option-1;
                end;
                menu(option);
            end;
            #13:
            begin
                case option of
                    0:
                    begin
                        pNo:=2;
                        for i:=0 to 1 do
                            with players[i] do
                            begin
                                timeIsUp:=FALSE;
                                name1:='Richard';
                                name2:='Fat';
                                icon:=defaultIcon[0];
                                mark:=0;
                                id:=i;
                                time.tms:=60000*20;
                                timeStore.tms:=time.tms;
                                time:=stdTime(time);
                                isWinning:=FALSE;
                                for j:=0 to 6 do
                                    hand[j]:=' ';
                                drawTiles(bag, bagCount, hand);
                            end;
                        writeln('Loading dictionary...');
                        loadDic('CSW12.txt', dic, dicMax);
                    end;
                    1: preStartOption(0, 0231);
                    2: loadGame('record.txt');
                    3: ;
                    4: halt;
                end;
                exit;
            end;
        else
            menu(option);
        end;
    end;
    
    procedure takeBack(var hand: array of char);
    begin
        typing:=FALSE;
        while puttedCount>0 do
        begin
            puttedCount:=puttedCount-1;
            for i:=0 to 6 do
                if hand[i]=' ' then
                begin
                    if putted[puttedCount].s then
                        hand[i]:='?'
                    else
                        hand[i]:=putted[puttedCount].c;
                    outputWords(hand);
                    break;
                end;
            outputBoardGrid(board, putted[puttedCount].x, putted[puttedCount].y);
            with putted[puttedCount] do
            begin
                curx:=x;
                cury:=y;
                x:=-1;
                y:=-1;
                c:=' ';
                s:=FALSE;
            end;
        end;
    end;
    
    function calcMark(aBoard:TBoard; var player:TPlayer; aWord: string; x1, y1, x2, y2: smallint):integer;
    var
        letterMultiple, wordMultiple: byte;
        i, j: smallint;
        tmpMark: integer;
        dirx: boolean;
    begin
        tmpMark:=0;
        wordMultiple:=1;
        dirx:= y1=y2;
        for i:=x1 to x2 do
            for j:=y1 to y2 do
            begin
                if dirx then
                    if aWord[i-x1+1]<>toUpperCase(aWord[i-x1+1]) then
                        continue
                    else
                else
                    if aWord[j-y1+1]<>toUpperCase(aWord[j-y1+1]) then
                        continue;
                letterMultiple:=1;
                if not usedPreSq[i, j] then
                begin
                    case boardPreSq[i-7, j-7] of
                        1: letterMultiple:=2;
                        2: letterMultiple:=3;
                        3: wordMultiple:=wordMultiple*2;
                        4: wordMultiple:=wordMultiple*3;
                    end;
                
                end;
                if dirx then
                    tmpMark:=tmpMark+tilesScore[ord(aWord[i-x1+1])-ord('A')]*letterMultiple
                else
                    tmpMark:=tmpMark+tilesScore[ord(aWord[j-y1+1])-ord('A')]*letterMultiple;
            end;
        tmpMark:=tmpMark*wordMultiple;
        player.mark:=player.mark+tmpMark;
        calcMark:=tmpMark;
    end;
    
    function done(var aBoard: TBoard; var player: TPlayer):boolean;
    var
        i: smallint;
        isOk: boolean;
        tempx, tempy: smallint;
        tmpBoard: array[0..14, 0..14] of char;
        startx, starty: smallint;
        tmpPlayer: TPlayer;
        tmpMark: integer;
        lastMark: integer;
        highestSingleWord: string;
        highestSingleWordScore: integer;
        invalidWords: string;
        
        procedure outputError(msg: string);
        const
            thisT=12;
            thisL=50;
        var
            count: integer;
        begin
            textcolor(lightred);
            gotoxy(thisL,thisT);
            write('/----------------------------\');
            gotoxy(thisL,thisT+1);
            write('|            ERROR           |');
            gotoxy(thisL,thisT+2);
            write('|', addSpace(copy(msg, 1, 28), 's', 28), '|');
            gotoxy(thisL,thisT+3);
            write('|', addSpace(copy(msg, 29, 28), 's', 28), '|');
            gotoxy(thisL,thisT+4);
            write('\----------------------------/');
            count:=0;
            repeat
                if players[pCur].timeIsUp then
                begin
                    continuePass:=continuePass+1;
                    break;
                end;
                if count=1000 then
                begin
                    if not updateTime(pCur) then
                    begin
                        drawTiles(bag, bagCount, players[pCur].hand);
                        outputWords(players[pCur].hand);
                        players[pCur].timeIsUp:=TRUE;
                        continuePass:=continuePass+1;
                        break;
                    end;
                    count:=0;
                end;
                count:=count+1;
                delay(1);
            until keyPressed;
            if players[pCur].timeIsUp then
                exit;
            readkey;
            outputBoard(board);
            outputPuttedTiles;
        end;
        
    begin
        invalidWords:='';
        tmpPlayer:=player;
        lastMark:=player.mark;
        done:=FALSE;
        connected:=FALSE;
        if (puttedCount<1) then
        begin
            //outputError('')
            exit;
        end;
        if firstRound and (puttedCount<2) then
        begin
            outputError('First move must contains at least two tiles!');
            exit;
        end;
        if firstRound then
        begin
            for i:=0 to puttedCount-1 do
                connected:=connected or (putted[i].x=7) and (putted[i].y=7);
            if not connected then
            begin
                outputError('First move must pass though center!');
                exit;
            end;
        end;
        if dirx then
        begin
            tempx:=putted[0].x-1;
            connected:=connected or ((aBoard[tempx, putted[0].y]<>' ') and (tempx>-1));
            tempx:=putted[puttedCount-1].x+1;
            connected:=connected or ((aBoard[tempx, putted[0].y]<>' ') and (tempx<15));
            for i:=putted[0].x to putted[puttedCount-1].x do
                if connected then
                    break
                else
                    connected:=((aBoard[i, putted[0].y-1]<>' ') and (putted[0].y-1>-1)) or ((aBoard[i, putted[0].y+1]<>' ') and (putted[0].y+1>-1)) or connected;
        end
        else
        begin
            tempy:=putted[0].y-1;
            connected:=connected or ((aBoard[putted[0].x, tempy]<>' ') and (tempy>-1));
            tempy:=putted[puttedCount-1].y+1;
            connected:=connected or ((aBoard[putted[0].x, tempy]<>' ') and (tempy<15));
            for i:=putted[0].y to putted[puttedCount-1].y do
                if connected then
                    break
                else
                    connected:=((aBoard[putted[0].x-1, i]<>' ') and (putted[0].x-1>-1)) or ((aBoard[putted[0].x+1, i]<>' ') and (putted[0].x+1>-1)) or connected;
        end;
        if not connected then
        begin
            outputError('Your tiles must connect to existing tiles!');
            exit;
        end;
        tmpBoard:=aBoard;
        for i:=0 to puttedCount-1 do
            with putted[i] do
                if s then
                    tmpBoard[x, y]:=toLowerCase(c)
                else
                    tmpBoard[x, y]:=c;
        highestSingleWordScore:=0;
        highestSingleWord:='';
        formedWordCount:=0;
        for i:=0 to 7 do
        begin
            formedWord[i]:='';
        end;
        isOk:=TRUE;
        if dirx then
        begin
            if not((tmpBoard[putted[0].x-1, putted[0].y]=' ') and (tmpBoard[putted[0].x+1, putted[0].y]=' ')) then
            begin
                tempx:=putted[0].x;
                tempy:=putted[0].y;
                while (tempx-1>-1) and (tmpBoard[tempx-1, tempy]<>' ') do
                    tempx:=tempx-1;
                startx:=tempx;
                starty:=tempy;
                repeat
                    formedWord[0]:=formedWord[0]+tmpBoard[tempx, tempy];
                    tempx:=tempx+1;
                until (tempx>14) or (tmpBoard[tempx, tempy]=' ');
                if isValid(formedWord[formedWordCount]) then
                begin
                    tmpMark:=calcMark(tmpBoard, tmpPlayer, formedWord[formedWordCount], startx, starty, tempx-1, tempy);
                    if tmpMark>highestSingleWordScore then
                    begin
                        highestSingleWord:=formedWord[formedWordCount];
                        highestSingleWordScore:=tmpMark;
                    end;
                end
                else
                begin
                    invalidWords:=invalidWords+toUpperCaseString(formedWord[formedWordCount])+' and ';
                    isOk:=FALSE;
                end;
                formedWordCount:=1;
            end;
            for i:=0 to puttedCount-1 do
                with putted[i] do
                begin
                    if ((tmpBoard[x, y-1]=' ') or (y=0)) and ((tmpBoard[x, y+1]=' ') or (y=14)) then
                        continue;
                    tempx:=x;
                    tempy:=y;
                    while (tempy-1>-1) and (tmpBoard[tempx, tempy-1]<>' ') do
                        tempy:=tempy-1;
                    startx:=tempx;
                    starty:=tempy;
                    repeat
                        formedWord[formedWordCount]:=formedWord[formedWordCount]+tmpBoard[tempx, tempy];
                        tempy:=tempy+1;
                    until (tempy>14) or (tmpBoard[tempx, tempy]=' ');
                    if isValid(formedWord[formedWordCount]) then
                    begin
                        tmpMark:=calcMark(tmpBoard, tmpPlayer, formedWord[formedWordCount], startx, starty, tempx, tempy-1);
                        if tmpMark>highestSingleWordScore then
                        begin
                            highestSingleWord:=formedWord[formedWordCount];
                            highestSingleWordScore:=tmpMark;
                        end;
                    end
                    else
                    begin
                        invalidWords:=invalidWords+toUpperCaseString(formedWord[formedWordCount])+' and ';
                        isOk:=FALSE;
                    end;
                    formedWordCount:=formedWordCount+1;
                end;
        end
        else
        begin
            if not((tmpBoard[putted[0].x, putted[0].y-1]=' ') and (tmpBoard[putted[0].x, putted[0].y+1]=' ')) then
            begin
                tempx:=putted[0].x;
                tempy:=putted[0].y;
                while (tempy-1>-1) and (tmpBoard[tempx, tempy-1]<>' ') do
                    tempy:=tempy-1;
                startx:=tempx;
                starty:=tempy;
                repeat
                    formedWord[0]:=formedWord[0]+tmpBoard[tempx, tempy];
                    tempy:=tempy+1;
                until (tempy>14) or (tmpBoard[tempx, tempy]=' ');
                if isValid(formedWord[formedWordCount]) then
                begin
                    tmpMark:=calcMark(tmpBoard, tmpPlayer, formedWord[formedWordCount], startx, starty, tempx, tempy-1);
                    if tmpMark>highestSingleWordScore then
                    begin
                        highestSingleWord:=formedWord[formedWordCount];
                        highestSingleWordScore:=tmpMark;
                    end
                end
                else
                begin
                    invalidWords:=invalidWords+toUpperCaseString(formedWord[formedWordCount])+' and ';
                    isOk:=FALSE;
                end;
                formedWordCount:=1;
            end;
            for i:=0 to puttedCount-1 do
            begin
                with putted[i] do
                begin
                    if ((tmpBoard[x-1, y]=' ') or (x=0)) and ((tmpBoard[x+1, y]=' ') or (x=14)) then
                        continue;
                    tempx:=x;
                    tempy:=y;
                    while (tempx-1>-1) and (tmpBoard[tempx-1, tempy]<>' ') do
                        tempx:=tempx-1;
                    startx:=tempx;
                    starty:=tempy;
                    repeat
                        formedWord[formedWordCount]:=formedWord[formedWordCount]+tmpBoard[tempx, tempy];
                        tempx:=tempx+1;
                    until (tempx>14) or (tmpBoard[tempx, tempy]=' ');
                    if isValid(formedWord[formedWordCount]) then
                    begin
                        tmpMark:=calcMark(tmpBoard, tmpPlayer, formedWord[formedWordCount], startx, starty, tempx-1, tempy);
                        if tmpMark>highestSingleWordScore then
                        begin
                            highestSingleWord:=formedWord[formedWordCount];
                            highestSingleWordScore:=tmpMark;
                        end;
                    end
                    else
                    begin
                        invalidWords:=invalidWords+toUpperCaseString(formedWord[formedWordCount])+' and ';
                        isOk:=FALSE;
                    end;
                    formedWordCount:=formedWordCount+1;
                end;
            end;
        end;
        if not isOk then
        begin
            for i:=0 to puttedCount-1 do
                with putted[i] do
                    tmpBoard[x, y]:=' ';
            outputError(copy(invalidWords, 1, length(invalidWords)-5)+' is not in the dictionary!');
            exit;
        end;
        aBoard:=tmpBoard;
        player:=tmpPlayer;
        if puttedCount=7 then
        begin
            player.mark:=player.mark+50;
            highestSingleWord:=formedWord[0];
        end;
        for i:=0 to puttedCount-1 do
            with putted[i] do
                usedPreSq[x, y]:=TRUE;
        drawTiles(bag, bagCount, player.hand);
        continuePass:=0;
        firstRound:=FALSE;
        with hist[histCount] do
        begin
            uid:=pCur;
            action:='D';
            words:=formedWord;
            mark:=player.mark-lastMark;
            time:=getNow;
            for i:=0 to puttedCount-1 do
            begin
                posx[i]:=putted[i].x;
                posy[i]:=putted[i].y;
            end;
            highestFormedWord:=highestSingleWord;
            highestFormedWordScore:=highestSingleWordScore;
        end;
        histCount:=histCount+1;
        done:=TRUE;
    end;
    
    procedure enterWord(var aBoard: TBoard; var player: TPlayer);
    const
        left=50;
        top=2;
    var
        i: smallint;
        tempx, tempy: smallint;
        isOk, isBlank: boolean;
        key: char;
        countMs: smallint;
    begin
        status:='Entering Word';
        countMs:=0;
        repeat
            repeat
                if countMs mod 1000 = 0 then
                    if not updateTime(pCur) then
                        exit;
                delay(1);
                gotoxy(curx*2+left, cury+top);
                changeColorByGrid(cury, curx);
                if countMs mod 500=0 then
                    if (countMs div 500) mod 2 =0 then
                    //if not ((putted[puttedCount-1].x=curx) and (putted[puttedCount-1].y=cury)) then
                        if dirx then
                            if OS then
                                write(#16#16)
                            else
                                write('>>')
                        else
                            if OS then
                                write(#31#31)
                            else
                                write('vv')
                    else
                        if aBoard[curx, cury]<>' ' then
                            write(aBoard[curx, cury]+' ')
                        else
                            if (putted[puttedCount-1].x=curx) and (putted[puttedCount-1].y=cury) then
                            begin
                                textcolor(14);
                                if putted[puttedCount-1].s then
                                    write(toLowerCase(putted[puttedCount-1].c)+' ')
                                else
                                    write(putted[puttedCount-1].c+' ');
                            end
                            else
                                write('[]');
                countMs:=countMs+1;
                gotoxy(80, 24);
            until keyPressed;
            key:=readkey;
            case key of
                #0:
                begin
                    key:=readkey;
                    if typing then
                        continue;
                    tempx:=curx;
                    tempy:=cury;
                    repeat
                        case key of
                            #72: tempy:=tempy-1;
                            #75: tempx:=tempx-1;
                            #77: tempx:=tempx+1;
                            #80: tempy:=tempy+1;
                        end;
                        if not(((tempx>-1) and (tempx<15) and (tempy>-1) and (tempy<15))
                                or ((tempx<>curx) and (tempy<>cury))) then
                            break;
                        //if (aBoard[tempx, tempy]=#0) then
                        //begin
                            gotoxy(curx*2+left, cury+top);
                            changeColorByGrid(cury, curx);
                            if aBoard[curx, cury]=' ' then
                                write('[]')
                            else
                                write(aBoard[curx, cury]+' ');
                            gotoxy(80, 24);
                            curx:=tempx;
                            cury:=tempy;
                            break;
                        //end
                        //else
                        //    continue;
                    until false;
                    countMs:=0;
                end;
                #13:
                begin
                    if done(aBoard, player) then
                    begin
                        tabing:=-1;
                        break;
                    end;
                end;
                #8:
                begin
                    if puttedCount=0 then
                        continue;
                    if puttedCount=1 then
                        typing:=FALSE;
                    puttedCount:=puttedCount-1;
                    for i:=0 to 6 do
                        if player.hand[i]=' ' then
                        begin
                            if putted[puttedCount].s then
                                player.hand[i]:='?'
                            else
                                player.hand[i]:=putted[puttedCount].c;
                            outputWords(player.hand);
                            break;
                        end;
                    gotoxy(curx*2+left, cury+top);
                    changeColorByGrid(cury, curx);
                    write('[]');
                    gotoxy(80, 24);
                    with putted[puttedCount] do
                    begin
                        curx:=x;
                        cury:=y;
                        x:=-1;
                        y:=-1;
                        c:=' ';
                        s:=FALSE;
                    end;
                    countMs:=500;
                end;
                #9:
                begin
                    textcolor(7);
                    outputActions(option);
                    tabing:=1;
                    break;
                end;
                ' ':
                begin
                    if not typing then
                        dirx:=not dirx;
                    countMs:=0;
                end;
                '1'..'9':
                begin
                    if typing then
                        continue;
                    gotoxy(curx*2+left, cury+top);
                    changeColorByGrid(cury, curx);
                    if aBoard[curx, cury]=' ' then
                        write('[]')
                    else
                        write(aBoard[curx, cury]+' ');
                    gotoxy(80, 24);
                    curx:=((ord(key)-ord('0')-1) mod 3 )*7;
                    cury:=(2-((ord(key)-ord('0')-1) div 3) )*7;
                    countMs:=0;
                end;
                'a'..'z','A'..'Z':
                begin
                    if (puttedCount=7)
                        or ((putted[puttedCount-1].x=curx) and (putted[puttedCount-1].y=cury) and (puttedCount<>0))
                        or (aBoard[curx, cury]<>' ') then
                        continue;
                    key:=toUpperCase(key);
                    isOK:=TRUE;
                    for i:=0 to puttedCount-1 do
                    begin
                        if (putted[puttedCount-1].x=curx) and (putted[puttedCount-1].y=cury) then
                        begin
                            isOk:=FALSE;
                            break;
                        end;
                    end;
                    isOk:=FALSE;
                    isBlank:=FALSE;
                    for i:=0 to 6 do
                    begin
                        if (player.hand[i]<>' ') and (player.hand[i]=key) then
                        begin
                            isOk:=TRUE;
                            player.hand[i]:=' ';
                            outputWords(player.hand);
                            break;
                        end;
                    end;
                    if not isOk then
                    begin
                        isOk:=FALSE;
                        for i:=0 to 6 do
                        begin
                            if player.hand[i]='?' then
                            begin
                                isOk:=TRUE;
                                player.hand[i]:=' ';
                                isBlank:=TRUE;
                                outputWords(player.hand);
                                break;
                            end;
                        end;
                        if not isOk then
                            continue;
                    end;
                    typing:=TRUE;
                    with putted[puttedCount] do
                    begin
                        c:=key;
                        x:=curx;
                        y:=cury;
                        s:=isBlank;
                    end;
                    puttedCount:=puttedCount+1;
                    textcolor(14);
                    //changeColorByGrid(cury, curx);
                    gotoxy(curx*2+left, cury+top);
                    if isBlank then
                        write(toLowerCase(key)+' ')
                    else
                        write(key+' ');
                    gotoxy(80, 24);
                    tempx:=curx;
                    tempy:=cury;
                    repeat
                        if dirx then
                            tempx:=tempx+1
                        else
                            tempy:=tempy+1;
                        if not((tempx>-1) and (tempx<15) and (tempy>-1) and (tempy<15)) then
                            break;
                        if (aBoard[tempx, tempy]=' ') then
                        begin
                            curx:=tempx;
                            cury:=tempy;
                            break;
                        end
                        else
                            continue;
                    until false;
                    countMs:=0;
                end;
            else;
            end;
        until false;
        gotoxy(curx*2+left, cury+top);
        changeColorByGrid(cury, curx);
        if aBoard[curx, cury]<>' ' then
            write(aBoard[curx, cury]+' ')
        else
            if (putted[puttedCount-1].x=curx) and (putted[puttedCount-1].y=cury) then
            begin
                textcolor(14);
                if putted[puttedCount-1].s then
                    write(toLowerCase(putted[puttedCount-1].c)+' ')
                else
                    write(putted[puttedCount-1].c+' ');
            end
            else
                write('[]');
        gotoxy(80, 24);
        textcolor(7);
    end;
    
    function exchange(pCur: smallint; var aBag: string; bagCount: smallint):boolean;
    const
        thisT=13;
        thisL=55;
    var
        tmpWords: array[0..6] of char;
        tmpWordsCount: smallint;
        i: smallint;
    begin
        takeBack(players[pCur].hand);
        for i:=0 to 6 do
            tmpWords[i]:=' ';
        tmpWordsCount:=0;
        exchange:=FALSE;
        gotoxy(thisL,thisT);
        write('/------------------\');
        gotoxy(thisL,thisT+1);
        write('|     EXCHANGE     |');
        gotoxy(thisL,thisT+2);
        write('|                  |');
        gotoxy(thisL,thisT+3);
        write('\------------------/');
        repeat
            if not updateTime(pCur) then
            begin
                for i:=0 to 6 do
                    if players[pCur].hand[i]=' ' then
                    begin
                        players[pCur].hand[i]:=tmpWords[tmpWordsCount-1];
                        tmpWordsCount:=tmpWordsCount-1;
                    end;
                outputWords(players[pCur].hand);
                break;
            end;
            if keyPressed then
            begin
                key:=readkey;
                case key of
                    #13:
                    begin
                        if tmpWordsCount=0 then
                            break;
                        with hist[histCount] do
                        begin
                            uid:=pCur;
                            action:='E';
                            mark:=tmpWordsCount;
                        end;
                        histCount:=histCount+1;
                        for i:=0 to tmpWordsCount-1 do
                            swapChr(tmpWords[i], aBag[random(100-bagCount+1)+1+bagCount]);
                        for i:=0 to 6 do
                            if players[pCur].hand[i]=' ' then
                            begin
                                players[pCur].hand[i]:=tmpWords[tmpWordsCount-1];
                                tmpWordsCount:=tmpWordsCount-1;
                            end;
                        outputWords(players[pCur].hand);
                        exchange:=TRUE;
                        break;
                    end;
                    'A'..'Z','a'..'z','?':
                    begin
                        key:=toUpperCase(key);
                        for i:=0 to 6 do
                            if players[pCur].hand[i]=key then
                            begin
                                gotoxy(thisL+2+tmpWordsCount*2,thisT+2);
                                write(key);
                                tmpWords[tmpWordsCount]:=key;
                                tmpWordsCount:=tmpWordsCount+1;
                                players[pCur].hand[i]:=' ';
                                outputWords(players[pCur].hand);
                                break;
                            end;
                    end;
                    #8:
                    begin
                        if tmpWordsCount<>0 then
                            for i:=0 to 6 do
                                if players[pCur].hand[i]=' ' then
                                begin
                                    tmpWordsCount:=tmpWordsCount-1;
                                    gotoxy(thisL+2+tmpWordsCount*2,thisT+2);
                                    write(' ');
                                    players[pCur].hand[i]:=tmpWords[tmpWordsCount];
                                    tmpWords[tmpWordsCount]:=' ';
                                    outputWords(players[pCur].hand);
                                    break;
                                end;
                    end;
                end;
            end;
        until false;
        outputWords(players[pCur].hand);
        outputBoard(board);
    end;
    
    procedure mainMsgHandle(page: smallint);
    const
        namePrefix='`2x';
        ptstimePrefix='`4x';
        wordPrefix='`7x';
        linePrefix='`7x';
        line=linePrefix+'- - - - - - - - - - - - - - -\n';
    var
        i, j: integer;
    begin
        case page of
            0:
            begin
                msgTmp:='';
                tmpStr:='           Dictionary\nValidate: '+dicCkStr[pCur]+'\n';
                if dicResult[pCur]=1 then
                    tmpStr:=tmpStr+'             `AxVALID';
                if dicResult[pCur]=0 then
                    tmpStr:=tmpStr+'            `CxINVALID';
                msgTmp:=msgTmp+tmpStr+'\n\n`7x';
                msgTmp:=msgTmp+' A|ABDEGHILMNRSTWXY\n';
                msgTmp:=msgTmp+' E|ADEGHLMNRSTX\n';
                msgTmp:=msgTmp+' I|DFNOST\n';
                msgTmp:=msgTmp+' O|BDEFHIMNOPRSUWXY\n';
                msgTmp:=msgTmp+' U|GHMNPRST\n';
                msgTmp:=msgTmp+' \n';
                msgTmp:=msgTmp+' B|AEIOY       N|AEOUY\n';
                msgTmp:=msgTmp+' C|H           P|AEIO\n';
                msgTmp:=msgTmp+' D|AEIO        Q|I\n';
                msgTmp:=msgTmp+' F|AEY         R|E\n';
                msgTmp:=msgTmp+' G|IOU         S|HIOT\n';
                msgTmp:=msgTmp+' H|AEIMO       T|AEIO\n';
                msgTmp:=msgTmp+' J|AO          W|EO\n';
                msgTmp:=msgTmp+' K|AIOY        X|IU\n';
                msgTmp:=msgTmp+' L|AIO         Y|AEOU\n';
                msgTmp:=msgTmp+' M|AEIMOUY     Z|AO\n';
                {msgTmp:=msgTmp+' B|AEIO Y      N|AE OUY\n';
                msgTmp:=msgTmp+' C|     H      P|AEIO\n';
                msgTmp:=msgTmp+' D|AEIO        Q|  I\n';
                msgTmp:=msgTmp+' F|AE   Y      R| E\n';
                msgTmp:=msgTmp+' G|  IOU       S|  IO HT\n';
                msgTmp:=msgTmp+' H|AEIO M      T|AEIO\n';
                msgTmp:=msgTmp+' J|A  O        W| E O\n';
                msgTmp:=msgTmp+' K|A IO Y      X|  I U\n';
                msgTmp:=msgTmp+' L|A IO        Y|AE OU\n';
                msgTmp:=msgTmp+' M|AEIOUMY     Z|A  O\n';}
                outputMainMsg(page, msgTmp);
            end;
            1:
            begin
                msgTmp:='      ';
                if 101-bagCount>=0 then
                    str(101-bagCount, msgTmp)
                else
                    msgTmp:='0';
                msgTmp:='      `Ex'+msgTmp+' Tiles Remaining\n\n';
                countTiles(tilesRemaining);
                for i:=0 to pNo-1 do
                    if i<>pCur then
                        for j:=0 to 6 do
                        begin
                            tmpChar:=players[i].hand[j];
                            if tmpChar=' ' then
                                continue;
                            if tmpChar<>'?' then
                                tilesRemaining[ord(tmpChar)-ord('A')]:=tilesRemaining[ord(tmpChar)-ord('A')]+1
                            else
                                tilesRemaining[26]:=tilesRemaining[26]+1;
                        end;
                for i:=0 to 8 do
                begin
                    for j:=0 to 2 do
                    begin
                        if tilesRemaining[i*3+j]=0 then
                            msgTmp:=msgTmp+'`8x'
                        else
                            msgTmp:=msgTmp+'`Fx';
                        str(tilesRemaining[i*3+j], tmpStr);
                        if length(tmpStr)=1 then
                            tmpStr:=' '+tmpStr;
                        if i*3+j<>26 then
                            msgTmp:=msgTmp+chr(ord('A')+i*3+j)+'  '
                        else
                            msgTmp:=msgTmp+'?  ';
                        if tilesRemaining[i*3+j]=0 then
                            msgTmp:=msgTmp+'`8x'
                        else
                            msgTmp:=msgTmp+'`Fx';
                        msgTmp:=msgTmp+tmpStr+'/';
                        if j<>2 then
                            msgTmp:=msgTmp+'    ';
                    end;
                    msgTmp:=msgTmp+'\n';
                    for j:=0 to 2 do
                    begin
                        if tilesRemaining[i*3+j]=0 then
                            msgTmp:=msgTmp+'`8x'
                        else
                            msgTmp:=msgTmp+'`Fx';
                        msgTmp:=msgTmp+' ';
                        str(tilesScore[i*3+j], tmpStr);
                        if length(tmpStr)=1 then
                            tmpStr:=tmpStr+' ';
                        msgTmp:=msgTmp+tmpStr+' ';
                        if tilesRemaining[i*3+j]=0 then
                            msgTmp:=msgTmp+'`8x'
                        else
                            msgTmp:=msgTmp+'`Fx';
                        str(tilesAmount[i*3+j], tmpStr);
                        if length(tmpStr)=1 then
                            tmpStr:=tmpStr+' ';
                        msgTmp:=msgTmp+'/'+tmpStr;
                        if j<>2 then
                            msgTmp:=msgTmp+'   ';
                    end;
                    msgTmp:=msgTmp+'\n';
                end;
                outputMainMsg(page, msgTmp);
            end;
        end;
    end;

begin
    bag:='AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSTTTTTTUUUUVVWWXYYZ??';
    //bag:='A???????????????????????????????????????????????????????????????????????????????????????????????????';
    randomize;
    repeat
        initTime:=getNow;
        clrscr;
        for i:=0 to 14 do
            for j:=0 to 14 do
                board[i,j]:=' ';
        tmpTime:=stdTime(getNow);
        pCur:=0;
        bagCount:=1;
        washBag(bag);
        firstRound:=TRUE;
        continuePass:=0;
        histCount:=0;
        for k:=0 to 1000 do
            with hist[k] do
            begin
                uid:=-1;
                mark:=-1;
                for i:=0 to 7 do
                begin
                    words[i]:='';
                    posx[i]:=-1;
                    posy[i]:=-1;
                end;
                time:=initTime;
                action:=' ';
            end;
        with hist[0] do
        begin
            time:=initTime;
            action:='S';
        end;
        histCount:=1;
        for i:=0 to 3 do
        begin
            page[i]:=0;
            dicCkStr[i]:='';
            dicResult[i]:=-1;
        end;
        OS:=pos('\', paramStr(0))<>0;
        menu(0);
        clrscr;
        outputBoard(board);
        repeat
            if continuePass>=pNo*2 then
                break;
            for i:=0 to pNo-1 do
            begin
                tilesUsedUp:=TRUE;
                for j:=0 to 6 do
                    if players[i].hand[j]<>' ' then
                        tilesUsedUp:=FALSE;
                if tilesUsedUp then
                    break;
            end;
            if tilesUsedUp then
                break;
            beginTime:=getNow;
            players[pCur].time.tms:=players[pCur].timeStore.tms;
            count:=99;
            puttedCount:=0;
            typing:=FALSE;
            dirx:=TRUE;
            curx:=7;
            cury:=7;
            option:=0;
            tabing:=0;
            mainMsgHandle(page[pCur]);
            for i:=0 to 6 do
                with putted[i] do
                begin
                    x:=-1;
                    y:=-1;
                    c:=' ';
                    s:=FALSE;
                end;
            outputBoard(board);
            outputPlayerProfile(pNo, players);
            outputPlayerProfileSingle(pCur, players[pCur], TRUE);
            outputActions(-1);
            outputWords(players[pCur].hand);
            repeat
                if players[pCur].timeIsUp then
                begin
                    continuePass:=continuePass+1;
                    break;
                end;
                if count=100 then
                begin
                    if not updateTime(pCur) then
                    begin
                        drawTiles(bag, bagCount, players[pCur].hand);
                        outputWords(players[pCur].hand);
                        players[pCur].timeIsUp:=TRUE;
                        continuePass:=continuePass+1;
                        break;
                    end;
                    count:=0;
                end;
                count:=count+1;
                case tabing of
                    0: enterWord(board, players[pCur]);
                    1:
                    begin
                        status:='Choosing action';
                        if not updateTime(pCur) then
                        begin
                            drawTiles(bag, bagCount, players[pCur].hand);
                            outputWords(players[pCur].hand);
                            players[pCur].timeIsUp:=TRUE;
                            continuePass:=continuePass+1;
                            break;
                        end;
                        if option=-1 then
                            option:=0;
                        if keyPressed then
                        begin
                            key:=readkey;
                            case key of
                                #0:
                                begin
                                    key:=readkey;
                                    case key of
                                        #72: option:=(option+3) mod 6;
                                        #75: option:=(option+5) mod 6;
                                        #77: option:=(option+1) mod 6;
                                        #80: option:=(option+3) mod 6;
                                    end;
                                    if not updateTime(pCur) then
                                    begin
                                        drawTiles(bag, bagCount, players[pCur].hand);
                                        outputWords(players[pCur].hand);
                                        players[pCur].timeIsUp:=TRUE;
                                        continuePass:=continuePass+1;
                                        break;
                                    end;
                                    {while keyPressed do
                                    begin
                                        readkey;
                                        if not updateTime(pCur) then
                                        begin
                                            drawTiles(bag, bagCount, players[pCur].hand);
                                            outputWords(players[pCur].hand);
                                            players[pCur].timeIsUp:=TRUE;
                                            continuePass:=continuePass+1;
                                            break;
                                        end;
                                    end;}
                                    outputActions(option);
                                end;
                                #9:
                                begin
                                    outputActions(-1);
                                    tabing:=2;
                                end;
                                #13:
                                begin
                                    case option of
                                        0:
                                        begin
                                            sort(players[pCur].hand);
                                            outputWords(players[pCur].hand);
                                        end;
                                        1:
                                        begin
                                            for i:=0 to 6 do
                                                swapChr(players[pCur].hand[i], players[pCur].hand[random(7)]);
                                            outputWords(players[pCur].hand);
                                        end;
                                        2:
                                        begin
                                            takeBack(players[pCur].hand);
                                        end;
                                        3:
                                        begin
                                            takeBack(players[pCur].hand);
                                            outputBoard(board);
                                            //players[pCur].time.tms:=-1;
                                            //players[pCur].time:=stdTime(players[pCur].time);
                                            players[pCur].timeIsUp:=TRUE;
                                            outputPlayerProfileSingle(pCur, players[pCur], FALSE);
                                            continuePass:=continuePass+1;
                                            with hist[histCount] do
                                            begin
                                                uid:=pCur;
                                                action:='F';
                                                mark:=0;
                                            end;
                                            histCount:=histCount+1;
                                            break;
                                        end;
                                        4:
                                        begin
                                            takeBack(players[pCur].hand);
                                            outputBoard(board);
                                            continuePass:=continuePass+1;
                                            with hist[histCount] do
                                            begin
                                                uid:=pCur;
                                                action:='P';
                                                mark:=0;
                                            end;
                                            histCount:=histCount+1;
                                            break;
                                        end;
                                        5:
                                            if (100-bagCount)>7 then
                                                if exchange(pCur, bag, bagCount) then
                                                begin
                                                    continuePass:=0;
                                                    break;
                                                end;
                                        6:
                                            if done(board, players[pCur]) then
                                            begin
                                                continuePass:=0;
                                                break;
                                            end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                    2:
                    begin
                        status:='Left page';
                        mainMsgHandle(page[pCur]);
                        repeat
                            count2:=1000;
                            repeat
                                if players[pCur].timeIsUp then
                                begin
                                    continuePass:=continuePass+1;
                                    break;
                                end;
                                if count2=1000 then
                                begin
                                    if not updateTime(pCur) then
                                    begin
                                        drawTiles(bag, bagCount, players[pCur].hand);
                                        outputWords(players[pCur].hand);
                                        players[pCur].timeIsUp:=TRUE;
                                        continuePass:=continuePass+1;
                                        break;
                                    end;
                                    count2:=0;
                                end;
                                count2:=count2+1;
                                delay(1);
                            until keyPressed;
                            if players[pCur].timeIsUp then
                                break;
                            key:=readkey;
                            case key of
                                #0:
                                begin
                                    key:=readkey;
                                    case key of
                                        #75, #77: page[pCur]:=(page[pCur]+1) mod 2;
                                    else
                                        key:=#0;
                                    end;
                                end;
                                #9:
                                begin
                                    tabing:=0;
                                    mainMsgHandle(page[pCur]);
                                end;
                            else
                                case page[pCur] of
                                    0:
                                    begin
                                        repeat
                                            case key of
                                                #0:
                                                begin
                                                    key:=readkey;
                                                    case key of
                                                        #75, #77: page[pCur]:=(page[pCur]+1) mod 2;
                                                    end;
                                                    break;
                                                end;
                                                'A'..'Z', 'a'..'z':
                                                begin
                                                    dicResult[pCur]:=-1;
                                                    if length(dicCkStr[pCur])<15 then
                                                    begin
                                                        dicCkStr[pCur]:=dicCkStr[pCur]+toUpperCase(key);
                                                        gotoxy(11+length(dicCkStr[pCur]), 5);
                                                        write(toUpperCase(key));
                                                        //mainMsgHandle(page[pCur]);
                                                    end;
                                                end;
                                                #9:
                                                begin
                                                    tabing:=0;
                                                    mainMsgHandle(page[pCur]);
                                                    break;
                                                end;
                                                #8:
                                                begin
                                                    dicResult[pCur]:=-1;
                                                    if length(dicCkStr[pCur])>0 then
                                                    begin
                                                        dicCkStr[pCur]:=copy(dicCkStr[pCur], 1, length(dicCkStr[pCur])-1); 
                                                        gotoxy(12+length(dicCkStr[pCur]), 5);
                                                        write(' ');        
                                                        gotoxy(14, 6);
                                                        write('       ');
                                                        //mainMsgHandle(page[pCur]);
                                                    end;
                                                end;
                                                #13:
                                                begin
                                                    if length(dicCkStr[pCur])>0 then
                                                    begin
                                                        if isValid(dicCkStr[pCur]) then
                                                            dicResult[pCur]:=1
                                                        else
                                                            dicResult[pCur]:=0;
                                                        if dicResult[pCur]=1 then
                                                        begin                      
                                                            gotoxy(14, 6);
                                                            write('       ');
                                                            gotoxy(15, 6);
                                                            textcolor(lightgreen);
                                                            write('VALID');
                                                        end;
                                                        if dicResult[pCur]=0 then
                                                        begin
                                                            gotoxy(14, 6);
                                                            textcolor(lightred);
                                                            write('INVALID');
                                                        end;
                                                        textcolor(7);
                                                        //mainMsgHandle(page[pCur]);
                                                    end;
                                                end;
                                            end;
                                            gotoxy(80,24);
                                            count3:=0;
                                            repeat
                                                if players[pCur].timeIsUp then
                                                begin
                                                    continuePass:=continuePass+1;
                                                    break;
                                                end;
                                                if count3=1000 then
                                                begin
                                                    if not updateTime(pCur) then
                                                    begin
                                                        drawTiles(bag, bagCount, players[pCur].hand);
                                                        outputWords(players[pCur].hand);
                                                        players[pCur].timeIsUp:=TRUE;
                                                        continuePass:=continuePass+1;
                                                        break;
                                                    end;
                                                    count3:=0;
                                                end;
                                                count3:=count3+1;
                                                delay(1);
                                            until keyPressed;
                                            if players[pCur].timeIsUp then
                                                break;
                                            key:=readkey;
                                        until false;
                                    end;
                                    1:
                                    begin
                                        repeat
                                            case key of
                                                #0:
                                                begin
                                                    key:=readkey;
                                                    case key of
                                                        #75, #77: page[pCur]:=(page[pCur]+1) mod 2;
                                                    end;
                                                    break;
                                                end;
                                                #9:
                                                begin
                                                    tabing:=0;
                                                    mainMsgHandle(page[pCur]);
                                                    break;
                                                end;
                                            end;
                                            gotoxy(80,24);
                                            count3:=0;
                                            repeat
                                                if players[pCur].timeIsUp then
                                                begin
                                                    continuePass:=continuePass+1;
                                                    break;
                                                end;
                                                if count3=1000 then
                                                begin
                                                    if not updateTime(pCur) then
                                                    begin
                                                        drawTiles(bag, bagCount, players[pCur].hand);
                                                        outputWords(players[pCur].hand);
                                                        players[pCur].timeIsUp:=TRUE;
                                                        continuePass:=continuePass+1;
                                                        break;
                                                    end;
                                                    count3:=0;
                                                end;
                                                count3:=count3+1;
                                                delay(1);
                                            until keyPressed;
                                            if players[pCur].timeIsUp then
                                                break;
                                            key:=readkey;
                                        until false;
                                    end;
                                end;
                            end;
                        until key<>#0;
                        if players[pCur].timeIsUp then
                            break;
                    end;
                else
                    tabing:=0;
                    break;
                end;
                delay(10);
            until false;
            outputPlayerProfileSingle(pCur, players[pCur], FALSE);
            players[pCur].timeStore:=players[pCur].time;
            pCur:=(pCur+1) mod pNo;
        until false;
        hist[histCount].action:='O';
        hist[histCount].time:=getNow;
        histCount:=histCount+1;
        mainMsgHandle(0);
        outputActions(-1);
        pCur:=pCur+pNo;
        outputPlayerProfile(pNo, players);
        outputWinningMsg();
        saveGame('record.txt');
        readkey;
    until false;
end.
//end
