//Developed by Rajarshi Roy and James Bruce, modified by Xubin Chen + Jip Roos (Multiple Lights, different colors)
// refactored a bit by Tim Tregubov
import java.awt.Robot; //java library that lets us take screenshots
import java.awt.AWTException;
import java.awt.event.InputEvent;
import java.awt.image.BufferedImage;
import java.awt.Rectangle;
import java.awt.Dimension;
import java.io.*;
import processing.serial.*; //library for serial communication
import http.requests.*;
import java.util.Properties;



Serial port; //creates object "port" of serial class
Robot robby; //creates object "robby" of robot class
Properties props;

// Default hue color value
final long DEFAULT_HUE = 52000; // purple

//configure this stuff in config.properties
String api_host;
String api_token;
String api_lights_string;
String poll_url;
boolean use_polling;
boolean update;

int lampCount = 1;
Runtime rut;
int time;
int poll_time;


void setup()
{
  println(Serial.list());
  port = new Serial(this, Serial.list()[0], 9600); //set baud rate
  size(100, 100); //window size (doesn't matter)
  rut = Runtime.getRuntime();
  poll_time = millis();
  try //standard Robot class error check
  {
    robby = new Robot();
  }
  catch (AWTException e)
  {
    println("Robot class not supported by your system!");
    exit();
  }

  readConfigs();
  if (api_lights_string !=null)
  {
     String response = curl("", api_lights_string, "GET");
     String[] tmp = {response};
     saveStrings("lights.tmp",  tmp);
     try
     {
       JSONObject json = loadJSONObject("lights.tmp");
       lampCount = json.size();
     } catch (Exception e)
     {
       println(e);
       exit();
     }
  }

}


void readConfigs() {
  try {
    props=new Properties();
    // load a configuration from a file inside the data folder
    props.load(new FileInputStream(dataPath("config.properties")));

    poll_url = props.getProperty("env.poll_url");
    use_polling = Boolean.parseBoolean(props.getProperty("env.use_polling"));
    api_host = props.getProperty("env.api_host");
    api_token = props.getProperty("env.api_token");
    api_lights_string = "http://"+api_host+"/api/"+api_token+"/lights/";

  }
  catch(IOException e) {
    println("couldn't read config file..." + e.toString());
  }
}



void draw()
{

  time = millis();

  int x = displayWidth; //possibly displayWidth
  int y = displayHeight; //possible displayHeight instead

  if ( use_polling  && (millis() - poll_time) > 500 )
  {
    update = testPoll();
    poll_time = millis();
  }

  if (update)
  {
    BufferedImage screenshot = robby.createScreenCapture(new Rectangle(new Dimension(x, y)));

    for (int i=1; i <= lampCount; i++)
    {
      if (i % 2 == 0)
      {
        screenshot = robby.createScreenCapture(new Rectangle(new Dimension(x, y)));
      }
      int[] avarage = getAvarageValues(screenshot, x, y, i-1, lampCount);
      String[] lamp = convertToColor(avarage[0], avarage[1], avarage[2], i);

      String bri = lamp[2];
      String sat = lamp[1];
      String hue = lamp[0];


      String json = "{\"on\": true,\"bri\":"+bri+",\"sat\":"+sat+",\"hue\":"+hue+",\"effect\":\"none\"}";
      String url = api_lights_string+i+"/state";

      String response = curl(json, url, "PUT");
    }

  }

  time = abs(150 - (millis() - time));
  delay((int) time); //delay for safety

}


String curl(String json, String url, String type)
{
  String output = "";
  String[] commands;

  if (type == "PUT")
  {
    String[] putcommands = {"curl", "--request", "PUT", "--data", json, url };
    commands = putcommands;
  } else if (type == "GET")
  {
    String[] getcommands = {"curl", "--request", "GET", url };
    commands = getcommands;
  } else { commands = new String[0]; }

  //println(commands);

  try
  {
    java.util.Scanner s = new java.util.Scanner(rut.exec(commands).getInputStream()).useDelimiter("\\A");
    output = s.hasNext() ? s.next() : "";
    //println(output);
  }
  catch (Exception e) {
    output = e.toString();
  }

  return output;
}

boolean testPoll()
{
  String response = curl("", poll_url, "GET").trim();
  boolean t = false;
  try {
    t = Boolean.parseBoolean(response);
  } catch (Exception e) {}
  println(" poll: " + t);
  return t;

}


//does some things like increasing saturation and returns a string hsv represation
String[] convertToColor(int r, int g, int b, int i) {
  // filter values to increase saturation
  int maxColorInt;
  int minColorInt;

  maxColorInt = max(r, g, b);
  if (maxColorInt == r) {
    // red
    if (maxColorInt < (225-20)) {
      r = maxColorInt + 10;
    }
  } else if (maxColorInt == g) {
    //green
    if (maxColorInt < (225-20)) {
      g = maxColorInt + 10;
    }
  } else {
    //blue
    if (maxColorInt < (225-20)) {
      b = maxColorInt + 10;
    }
  }

  //minimise smallest
  minColorInt = min(r, g, b);
  if (minColorInt == r) {
    // red
    if (minColorInt > 20) {
      r = minColorInt - 20;
    }
  } else if (minColorInt == g) {
    //green
    if (minColorInt > 20) {
      g = minColorInt - 20;
    }
  } else {
    //blue
    if (minColorInt > 20) {
      b = minColorInt - 20;
    }
  }

  //Convert RGB values to HSV(Hue Saturation and Brightness)
  long[] hsv = new long[3];
  RGBtoHSB(r, g, b, hsv);

  colorMode(HSB, 65535, 255, 255);
  if (i == 2) {
    background(hsv[0], hsv[1], hsv[2]);
  }


  String hue = String.valueOf(hsv[0]);
  String sat = String.valueOf(hsv[1]);
  String bri = String.valueOf(hsv[2]);
  String[] colorArray = {
    hue, sat, bri
  };

  return colorArray;
}

//maybe a faster way to do this?
int[] getAvarageValues(BufferedImage screenshot, int x, int y, int lampid, int lampCount) {
  int skipValue = 20;
  //sets of 8 bytes are: Alpha, Red, Green, Blue
  int r=0;
  int g=0;
  int b=0;
  int pixel; //ARGB variable with 32 int bytes where
  // need to be a round number
  int lampWidth = x/lampCount;
  int start = lampWidth * lampid;
  int end = lampWidth * (lampid + 1);
  int i=0;
  int j=0;
  //I skip every alternate pixel making my program 4 times faster
  for (i=start; i<end; i=i+skipValue) {
    for (j=0; j<y; j=j+skipValue) {
      pixel = screenshot.getRGB(i, j); //the ARGB integer has the colors of pixel (i,j)
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

  //println(r+","+g+","+b);
  int[] valueArray = {
    r, g, b
  };
  return valueArray;
}

//
long[] RGBtoHSB(int r, int g, int b, long[] hsbvals) {
  long hue, saturation, brightness;
  if (hsbvals == null) {
    hsbvals = new long[3];
  }
  int cmax = (r > g) ? r : g;
  if (b > cmax) cmax = b;
  int cmin = (r < g) ? r : g;
  if (b < cmin) cmin = b;
  brightness = cmax;
  if (cmax != 0)
    saturation = (cmax - cmin) * 255 / cmax;
  else
    saturation = 0;
  //println(cmax);
  //println(cmin);
  if (saturation == 0)
    hue = DEFAULT_HUE;
  else {
    // Need to be fixed!
    float tempHue;
    float redc = ((float) (cmax - r)) / ((float) (cmax - cmin));
    float greenc = ((float) (cmax - g)) / ((float) (cmax - cmin));
    float bluec = ((float) (cmax - b)) / ((float) (cmax - cmin));
    if (r == cmax)
      tempHue = bluec - greenc;
    else if (g == cmax)
      tempHue = 2.0f + redc - bluec;
    else
      tempHue = 4.0f + greenc - redc;
    tempHue = tempHue / 6.0f;
    if (tempHue < 0)
      tempHue = tempHue + 1.0f;
    hue = (long) (tempHue * 65535);
  }
  hsbvals[0] = hue;
  hsbvals[1] = saturation;
  hsbvals[2] = brightness;
  //println(hsbvals);
  return hsbvals;
}
