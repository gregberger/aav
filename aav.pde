
/**
 * aav : another audio visualizer
 *
 * Super formula implementation found on Alexander Miller's youtube channel
 * https://youtu.be/u6arTXBDYhQ
 *
 * Sound analysis stolen from https://github.com/andrele/Starburst-Music-Viz
 *
 */

import ddf.minim.analysis.*;
import ddf.minim.*;
import controlP5.*;



Minim       minim;
AudioPlayer player=null;
FFT         fft;
ControlP5 cp5;
BeatDetect beat;
float t=0.1;
float MULT_1=0.01;
float MULT_2=0.1, MULT_4,MULT_5,MULT_6;
int MULT_3=0;
boolean crazy = false;

String filename;

void setup() {
  size(1000, 800);
  pixelDensity(2);
  

  minim = new Minim(this);
  cp5 = new ControlP5(this);
  beat = new BeatDetect();
  selectFile();

  cp5.addSlider("MULT_1").setRange(0.0,20.0).setValue(10.3).setPosition(10,10);
  cp5.addSlider("MULT_2").setRange(0.01,20.0).setValue(12.2).setPosition(10,30);
  cp5.addSlider("MULT_3").setRange(0,50).setPosition(10,50);
  cp5.addSlider("MULT_4").setRange(0.01,20.0).setValue(14.3).setPosition(10,70);
  cp5.addSlider("MULT_5").setRange(0.01,20.0).setValue(0.81).setPosition(10,90);
  cp5.addSlider("MULT_6").setRange(0.01,20.0).setPosition(10,110);
  cp5.addToggle("crazy").setLabel("Go crazy").setPosition(200, 40);
  cp5.addButton("selectFile").setPosition(200,10);
  colorMode(HSB);

  strokeWeight(1.0);
  noFill();
}

void draw() {
  background(0);
  pushMatrix();
  if (player != null && player.isPlaying()) {
    fft.forward(player.mix);
    beat.detect(player.mix);
    float avg=0;
    translate(width/2, height/2);

    beginShape();
    for (float i = 0; i<=2*PI; i+=0.01) {
      int idx = int(constrain(map(i, 0, 2*PI, 0, 29), 0, 29));
      avg = fft.getAvg(idx);
      
      // What is the centerpoint of the this frequency band?
      float centerFrequency = fft.getAverageCenterFrequency(idx);
      // What is the average width of this freqency?
      float averageWidth = fft.getAverageBandWidth(idx);
      // Get the left and right bounds of the frequency
      float lowFreq = centerFrequency - averageWidth/2;
      float highFreq = centerFrequency + averageWidth/2;
      // Convert frequency widths to actual sizes
      int xl = (int)fft.freqToIndex(lowFreq);
      int xr = (int)fft.freqToIndex(highFreq);
      
      float theta = i;
      if (crazy) {
        theta = avg + MULT_6*cos(t);
      }
      
      
      if(beat.isOnset()){
        stroke(avg*360, 255, 255, 255);
      }else{
        fill(avg*360, 255, 255, avg*255);  
      }
      float rad = r(
        theta, 
        MULT_1*sin(t), //  a
        MULT_2*cos(xr),//cos(xr)*avg, //xl*.9, //cos(i)*pow(t, 3), // b
        MULT_3, //cos(t)*avgLog, // m
        MULT_4*sin(avg),//sin(xl), // n1
        MULT_5*-avg, // cos(xr-xl), //avgLog, // n2
        MULT_6// n3
        );

      float x = rad * cos(theta) * (width/20);
      float y = rad * sin(theta) * (width/20);
      strokeWeight(abs(sin(avg))*10.0);
      
      vertex(x, y);
      
      
    }
    endShape();
    t+=0.0001;
  }
  popMatrix();
}



float r(float theta, float a, float b, float m, float n1, float n2, float n3) {
  return pow(pow(abs(cos(m*theta/4.0)/a), n2) +  pow(abs(sin(m*theta/4.0)/b), n3), -1.0/n1);
}

/*
 * The selectInput callback 
 **/
void fileSelected(File selection) {
  if (selection == null) {
    println("cancelled");
  } else {
    filename = selection.getAbsolutePath();
    player = minim.loadFile(filename, 2048);
    fft = new FFT(player.bufferSize(), player.sampleRate());
    fft.logAverages(22, 3);
    player.loop();
  }
}

void selectFile() {
  reset();
  selectInput("Select an audio file to continue :", "fileSelected");
}


void keyPressed() {
  switch(key){
     case 'f':{
        selectFile();
        break; 
     }
     case 'c':{
        crazy = !crazy;
        break;
     }
     case 'h':{
       // h hides the controls
       if(cp5.isVisible()){
        cp5.hide(); 
       }else{
        cp5.show(); 
       }
       break;
     }
     
  }
}

void reset() {
  background(0);
  t = 0.1;
  crazy = false;
  minim.stop();
  filename = null;
  player = null;
  fft = null;
}
void stop() {
  player.close();
  minim.stop();
  super.stop();
}