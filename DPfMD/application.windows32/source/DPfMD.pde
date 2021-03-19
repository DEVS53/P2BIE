/*
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import processing.serial.*;
import controlP5.*;
import java.util.*;

Serial port;
PrintWriter output;

ControlP5 cp5;
Textarea valueFld;
Textarea gra; 
Textlabel logFld;

PFont font;
final int fntSize = 11;
final int menuBarW = 65;
color gray = color(205,205,205);

String[] data;
String fileName;

String portName;
int baudRate;
int[] baud = {9600, 14400, 19200, 28800, 38400, 57600, 115200};
int scm;
int[] sc = {1, 2, 3};
int itemSelected;

int index = 0;
int counter = 0;
int count = 0;
int inByte = 0;
int a,b,c=0;
byte[] inBuffer = new byte[2];
float muestrasSeg=1;
float rmsv=0;

float yIn;
float x1, y1, x2, y2;
float x3, y3, x4, y4;

int maxgraf=1366;
int[] grafica=new int[maxgraf];
int ng=0;
int dato;
String buffer;
float factor=35000/400;
float offs=0;
int ADCmin=0;
int ADCmax=4096;
long t=0;
long millisIni=0;
int escribiendo=0;

color white = color(255, 255, 255);
color black = color(0, 0, 0);
color gray2= color(119,119,119);

boolean connected = false;
boolean showGraph = false;
boolean showText = false;
boolean midiendo = false;

//int[] y = new int[0];

String getDateTime()
{
 int s = second();
 int m = minute();
 int h = hour();
 int day = day();
 int mo = month();
 int yr = year();

// Avoid slashes which create folders
String date = nf(mo,2)+nf(day,2)+yr+"_";
String time = nf(h,2)+nf(m,2)+nf(s,2);
String dateTime = date+time;
return dateTime;
}

void setup() {
 fullScreen();
 if (frame != null) {
   surface.setResizable(false);
 }
 background(white);
 factor=(ADCmax-ADCmin)/(0-800.0);
 offs=800.0-ADCmin/factor;
 println(factor);
 println(offs);
 cp5 = new ControlP5(this);
 font = createFont("SourceCodePro-Regular.tif", fntSize);
 String[] ports = Serial.list();
 List p = Arrays.asList(ports);
 showGraph = true;
 
 cp5.addScrollableList("SerialPorts")
     .setPosition(10, 3)
     .setSize(230, 90)
     .setCaptionLabel("Avalible ports")
     .setBarHeight(18)
     .setItemHeight(18)
     .setFont(font)
     .addItems(p);
      
 List b = Arrays.asList("9600","14400","19200","28800","38400","57600","115200");      
 cp5.addScrollableList("Baud")    
      .setPosition(250, 3)
      .setSize(60,90)
      .setBarHeight(18)
      .setItemHeight(18)
      .setFont(font)
      .addItems(b);

 List s = Arrays.asList("Mode 1","Mode 2", "Mode 3");
 cp5.addScrollableList("Modes")    
      .setPosition(320, 3)
      .setSize(60,90)
      .setBarHeight(18)
      .setItemHeight(18)
      .setFont(font)
      .addItems(s);
 
 cp5.addButton("Conecta")
     .setPosition(390, 3)
     .setFont(font)
     .setSize(85,19)
     .setCaptionLabel("Connect");
     
 cp5.addButton("Desconecta")
     .setPosition(390,23)
     .setFont(font)
     .setSize(85,19)
     .setCaptionLabel("Disconnect");
           
 cp5.addButton("Save")
     .setPosition(485,3)
     .setFont(font)
     .setSize(70,19)
     .setCaptionLabel("Save");
 
 cp5.addButton("Open")
     .setPosition(485,23)
     .setFont(font)
     .setSize(70,19)
     .setCaptionLabel("Open");
      
 cp5.addButton("ScreenShot")
     .setPosition(565,3)
     .setFont(font)
     .setSize(80,19)
     .setCaptionLabel("Screenshot");
 
 cp5.addButton("ClrScrn")
     .setPosition(565,23)
     .setFont(font)
     .setSize(80,19)
     .setCaptionLabel("Clean");
      
 cp5.addButton("GrabaStr")
     .setPosition(655,3)
     .setFont(font)
     .setSize(90,19)
     .setCaptionLabel("Start saving");
  
 cp5.addButton("RescanPorts")
     .setPosition(655,23)
     .setFont(font)
     .setSize(90,19)
     .setCaptionLabel("Rescan Ports");
     
 logFld = cp5.addTextlabel("Log")
     .setPosition(390,45)
     .setSize(360, 18)
     .setFont(font)
     .setLineHeight(14);
 
 cp5.addButton("Quit")
     .setPosition(width-60,3)
     .setFont(font)
     .setSize(50,19);

 cp5.setColorBackground(gray);
 cp5.setColorCaptionLabel(black);
 cp5.setColorForeground(gray2);
 cp5.setColorValueLabel(black);
 cp5.setColorActive(black);

}
     
void draw() {
 // **** Menu Bar **** // 
 fill(128);
 rect(0, 0, width-1, menuBarW);
 // Procesa entradas
 if (connected) leePuertoBin();
 if (showGraph) dibuja();clm();
 if (midiendo) {
   muestrasSeg=rmsv;
   //text(muestrasSeg,900,20);
 }
 if (connected & !midiendo & t>1000){ t=0;millisIni=millis();midiendo=true;}
}

void dibuja(){
  background(white);
  strokeWeight(1);
  stroke(black);
 int yant=0;
 int y=0;
  for (int i = 1; i < maxgraf-1; i++) {
    int j=(i+ng) % maxgraf;
    y=int((grafica[j]/factor)+offs);
    line(i-1,yant,i,y);
    yant=y;
  }
}

void leePuertoBin(){
  while (port.available() > 0) {
       c=port.read();
   if (c>127) a=c;
   else{ b=(a&127)|(c<<7);
     insertaDato(b);
   }
   }
}

void leePuerto(){
  while (port.available() > 0) {
    buffer = port.readStringUntil('\n');
    if ( buffer != null && buffer.length() >= 2 ) {insertaDato(parseInt(buffer.trim()));}
   }
}

void insertaDato(int dato){
  t++; ng++;
  if(ng>maxgraf-1) ng=0;
    grafica[ng]=dato;
  if (escribiendo==1) output.println(dato);
  if (ng==0);
    clm();
}

void clm(){
  long vm=0;
  long rms=0;
  for(int i=1; i<maxgraf; i++){vm+=grafica[i];}
  vm/=maxgraf;
  for(int i=1; i<maxgraf; i++){rms+=pow((grafica[i]-vm), 2);}
  rms/=maxgraf;
  rmsv=rms;
}

void ClrScrn() {
   background(white);
   for (int i = 0; i < maxgraf-1; i++) grafica[i]=0;
   ng=0;
}

void SerialPorts(int n ) {
 /* request selected item from Map based on index n */
 portName = cp5.get(ScrollableList.class, "SerialPorts").getItem(n).get("name").toString();
 logFld.setText("Seleccionado: "+portName);
 background(white);
}

void Baud(int n ) {
  baudRate = baud[n];
  logFld.setText("baudRate: "+baudRate);
  background(white);
}

void Modes(int n){
  scm = sc[n];
  logFld.setText("Mode: "+scm);
  if (n==1){port.write("m1" + "\r");}
  else if (n==2){port.write("m2" + "\r");}
  else if (n==3){port.write("m3" + "\r");}
}
void EmptyArray(){
 // y = new int[0];
}

void Conecta() {
 // **** Zero out data array **** //
 EmptyArray();
 port = new Serial(this, portName, baudRate);
 connected = true;
 port.write("START" + "\r");
 logFld.setText("Conected.");
 millisIni=millis();
 t=0;
}

void Desconecta() {
  port.stop();
  yIn = 0;
  count = 0;
  connected = false;
  midiendo=false;
  port.write("STOP" + "\r");
  logFld.setText("Disconected.");
}

void Save() {
  String dateTimeStr = getDateTime();
  String fileToSave = dateTimeStr+".txt";
  String[] data = new String[grafica.length];
  for (int i = 0; i < grafica.length; i++) {
    data[i] = grafica[i]+",";
  }
  saveStrings(fileToSave, data);
  logFld.setText("Datos grabados.");
}

void ScreenShot() {
 String dateTimeStr = getDateTime();
 String imageOut = dateTimeStr+".png";
 save(imageOut);
 logFld.setText("Screenshot.");
}

void RescanPorts(){
 logFld.setText("Rescan ports.");
 cp5.get(ScrollableList.class, "SerialPorts").clear();
 String[] ports = Serial.list();
 List p = Arrays.asList(ports);
 cp5.get(ScrollableList.class, "SerialPorts").addItems(p);
}

void fileSelected(File selection){
 if (selection != null) {
  index = 0;
  counter = 0;
  fileName = selection.getAbsolutePath(); 
  logFld.setText("Fichero: " + fileName);
  data = loadStrings(selection.getAbsolutePath());
  println (data.length);
  for (int i=0; i<data.length;i++){ grafica[i]=parseInt(split(data[i],","))[0]; }
  dibuja();
 }
}

void Open(){
 selectInput("Select a file to process:", "fileSelected");
}

void GrabaStr(){
  if(escribiendo==1){
    escribiendo=0;
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
    cp5.getController("Save").setCaptionLabel("Save");
  }
  else{
    String dateTimeStr = getDateTime();
    String fileToSave = dateTimeStr+".txt";
    output = createWriter(fileToSave); 
    escribiendo=1;
    output.print("Muestras/segundo: ");
    output.println(muestrasSeg);
    cp5.getController("Start saving").setCaptionLabel("Stop saving");
  }
}

void Quit(){exit();}	
