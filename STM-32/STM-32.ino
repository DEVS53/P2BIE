HardwareTimer timerN2(2);      
unsigned int n=0;
byte a,b;
  unsigned long lectSec=500;
  unsigned long n1,n2;
  unsigned long frec=72000000;

const int bSize = 16;
#define separador ","
char *p;
char Buffer[bSize];  
int Ind=0;
char x=0;
boolean stringComplete = false; 
String Comando;
String Data;

void setup(){
  Serial.begin(115200);                
  delay(300);                           
  Serial.println("Empiezo");
}

void loop() {
    serialEvent();
    if (stringComplete){
    Comando=String(strtok_r(Buffer,separador,&p)); 
    Data=String(strtok_r(NULL,separador,&p));
    clearBuffer();
    Comando.toUpperCase();
    if (Comando=="*IDN?"){Serial.println("Jmmm,Gausimetro,001,V0.1");}
    else if (Comando=="START"){ timerN2.attachInterrupt(1,fcontrol);}
    else if (Comando=="STOP"){ timerN2.detachInterrupt(1);}
    else if (Comando=="N?"){Serial.println(lectSec);}
    else if (Comando=="N"){if (Data.toInt()==4294957296){
      Serial.print("No se pueden alcanzar esas medidas");}else{lectSec=Data.toInt(); iniciaT2();}
      }
    else if (Comando=="M1"){m1();}
    else if (Comando=="M2"){m2();}
    else if (Comando=="M3"){m3();}
  }
}

void m1(){
  pinMode(PB7,INPUT);
  pinMode(PB8,INPUT);
  pinMode(PB9,OUTPUT);
  digitalWrite(PB9,HIGH);
}

void m2(){
  pinMode(PB7,INPUT);
  pinMode(PB8,OUTPUT);
  pinMode(PB9,INPUT);
  digitalWrite(PB8,HIGH);
}

void m3(){
  pinMode(PB7,OUTPUT);
  pinMode(PB8,INPUT);
  pinMode(PB9,INPUT);
  digitalWrite(PB7,HIGH);
}

void iniciaT2(){ 
  n1=(frec/(lectSec*65000))+1;
  n2=frec/(lectSec*n1);
  timerN2.pause();              
  timerN2.attachInterrupt(1,fcontrol);                            
  timerN2.setPrescaleFactor(n1);    
  (TIMER2->regs).gen->ARR = n2-1;     
  (TIMER2->regs).gen->CNT = 00;
  (TIMER2->regs).gen->CCR1 =(TIMER2->regs).gen->ARR/2;
  timerN2.refresh();
  timerN2.resume();
}

void fcontrol(){    
 n=analogRead(PA1);
 a=(n&0b01111111)|0b10000000;
 b=(n&0b111110000000)>>7;
 b=n>>7;
 Serial.write(a);
 Serial.write(b);
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read(); 
    if (inChar == '\n' || inChar=='\r') {
    stringComplete = true;
    } 
    else {
    Buffer[Ind]= inChar;
    Ind++;
    Buffer[Ind]=NULL;
    }
  }
}

void clearBuffer() {
    Ind=0;
    Buffer[0]=NULL;
    stringComplete = false;
}
