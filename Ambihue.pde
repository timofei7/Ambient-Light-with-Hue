//Developed by Rajarshi Roy and James Bruce
//Modified by Xubin Chen
//Modified by Jip Roos (Multiple Lights, different colors)

import java.awt.Robot; //java library that lets us take screenshots
import java.awt.AWTException;
import java.awt.event.InputEvent;
import java.awt.image.BufferedImage;
import java.awt.Rectangle;
import java.awt.Dimension;
import java.io.*;
import java.util.Scanner;
import java.awt.Color;
import processing.serial.*; //library for serial communication
 
Serial port; //creates object "port" of serial class
Robot robby; //creates object "robby" of robot class
 
void setup()
{
  println(Serial.list());
  port = new Serial(this, Serial.list()[0],9600); //set baud rate
  size(100, 100); //window size (doesn't matter)
  try //standard Robot class error check
  {
  robby = new Robot();
  }
  catch (AWTException e)
  {
  println("Robot class not supported by your system!");
  exit();
  }

}
 
void draw()
{

// How much lamps do you want to split up the colors?
int lampCount = 3;
int x = displayWidth; //possibly displayWidth
int y =  displayHeight; //possible displayHeight instead

//get screenshot into object "screenshot" of class BufferedImage
BufferedImage screenshot = robby.createScreenCapture(new Rectangle(new Dimension(x,y)));

// create array for lamps
String[][] colorArrays = new String [lampCount][3];
for(int i = 0; i<lampCount; i++){
  float[] avarage = getAvarageValues(screenshot,x,y,i,lampCount);
  String[] lamp = convertToColor(avarage[0], avarage[1], avarage[2]);
  colorArrays[i] = lamp;
}

// doesnt get it working on windows (maybe need to study processing more)
//port.write(0xff); //write marker (0xff) for synchronization
//port.write((byte)(r)); //write red value
//port.write((byte)(g)); //write green value
//port.write((byte)(b)); //write blue value

delay(100); //delay for safety
Runtime rut = Runtime.getRuntime();

//System.out.println(s);

//This portion calls the bash / .sh file which allows Curl PUT to write the HSV values to Philips Hue
try{

   // create a new array of 4 strings
   String[] cmdArray = new String[1 + lampCount * 3];

   // Location for the file where we send the PUT requests
   // .bat is for windows, change it to sh for linux or mac os
   cmdArray[0] = "C:\\Users\\Jip\\Documents\\AmbiHue\\AmbiHue.bat";
  
   for(int i=1; i<lampCount*3+1; i=i+3){
     for(int j = 0; j<3; j++){
       if(i<3){
         cmdArray[i+j] = colorArrays[i-1][j];
       } else {
         //println(i);
         cmdArray[i+j] = colorArrays[(i-1)/3][j];
       }
     }
   }
   
  Process process = rut.exec(cmdArray);
  
   /*Scanner scanner = new Scanner(process.getInputStream());
  while (scanner.hasNext()) {
      System.out.println(scanner.nextLine());
  }*/
  
}catch(IOException e1){
  e1.printStackTrace();
}
finally{}
}


// Function for converting color from RGB to HSV (and saturnating colors)
String[] convertToColor(float r, float g, float b) {
// filter values to increase saturation
float maxColorInt;
float minColorInt;
 
maxColorInt = max(r,g,b);
if(maxColorInt == r){
  // red
  if(maxColorInt < (225-20)){
    r = maxColorInt + 20;  
  }
}
else if (maxColorInt == g){
  //green
  if(maxColorInt < (225-20)){
    g = maxColorInt + 20;  
  }
}
else {
   //blue
   if(maxColorInt < (225-20)){
    b = maxColorInt + 20;  
  }  
}
 
//minimise smallest
minColorInt = min(r,g,b);
if(minColorInt == r){
  // red
  if(minColorInt > 20){
    r = minColorInt - 20;  
  }
}
else if (minColorInt == g){
  //green
  if(minColorInt > 20){
    g = minColorInt - 20;  
  }
}
else {
   //blue
   if(minColorInt > 20){
    b = minColorInt - 20;  
  }  
}

//Convert RGB values to HSV(Hue Saturation and Brightness) 
float[] hsv = new float[3];
Color.RGBtoHSB(Math.round(r),Math.round(g),Math.round(b),hsv);
//You can multiply SAT or BRI by a digit to make it less saturated or bright
float HUE= hsv[0] * 65535;
float SAT= hsv[1] * 255;
float BRI= hsv[2] * 255;

//Convert floats to integers
String hue = String.valueOf(Math.round(HUE));
String sat = String.valueOf(Math.round(SAT));
String bri = String.valueOf(Math.round(BRI));
String[] colorArray = {hue, sat, bri};

return colorArray;
}

float[] getAvarageValues(BufferedImage screenshot, int x, int y, int lampid, int lampCount) {
  int skipValue = 4;
  //sets of 8 bytes are: Alpha, Red, Green, Blue
  float r=0;
  float g=0;
  float b=0;
  int pixel; //ARGB variable with 32 int bytes where
  // need to be a round number
  int lampWidth = Math.abs(x/lampCount);
  int start = lampWidth * lampid;
  int end = lampWidth * (lampid + 1);
  int i=0;
  int j=0;
  //I skip every alternate pixel making my program 4 times faster
  for(i=start; i<end; i=i+skipValue){
    for(j=0; j<y; j=j+skipValue){
      pixel = screenshot.getRGB(i,j); //the ARGB integer has the colors of pixel (i,j)
      r = r+(int)(255&(pixel>>16)); //add up reds
      g = g+(int)(255&(pixel>>8)); //add up greens
      b = b+(int)(255&(pixel)); //add up blues
    }
  }
  
  int aX = x/skipValue;
  int aY = y/skipValue;
  r=r/(aX*aY); //average red
  g=g/(aX*aY); //average green
  b=b/(aX*aY); //average blue
  if(lampid==1){
    background(r,g,b);
  }
  
  //println(r+","+g+","+b);
 float[] valueArray = {r, g, b};
 return valueArray;
}

