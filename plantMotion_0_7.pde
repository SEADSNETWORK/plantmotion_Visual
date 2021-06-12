// motion tracking based on the principle of downsampling
// and comparing prev. vs current values of H and B (not S)
// Controls:
// Threshold:..................LEFT/RIGHT
// Pixel Size:.................UP/DN
// Matrix on/off:..............M
// targetRect..................T
// Video clear screen on/off:..C
//
//Limiting the cell size to 4, or the resolution would become too high for an array
/*
methods:
 
 setup               :
 draw                :
 void cellTime       :
 void easing         :
 void seeker         :
 void highliteCells(float transx, float transy, PVector newpv)  :
 void agents()       :
 void virus()        :
 void dish()         :
 void web()          :
 void filter2()      :
 void filter3()      :
 void makeCells()    :
 void overlay()      :
 void text()         :
 void keyPressed()   :
 
 keys:
 
 S:   save frame
 M:   cell matrix on/off
 C:   solidbackground on/off
 T:   target rectangle on/off
 U:   User interface/helpscreen
 I:   inverter on/off. Active cell visibility
 
 cursor keys:
 UP/DOWN    : change cell size. Minimum = 4px
 LEFT/RIGHT : change threshold 
 */
import processing.video.*;
PFont font;

Capture cam;
boolean viewmatrix = true;// view the cell matrix
boolean solidBackground= false;// toggle videostream/solid background
boolean targetRect = false;// display target rectangles
boolean hit = false;// seeker is hitting agents 'center of area' (not user selectable)
boolean UI = true;// visibility of the user interface
boolean inverter = false;// only motion cells are visible when true
float h, s, b;

// cell variables
int  lifeSpan = 1000;// lifetime of a cell in milliseconds
int cellCounter = 0;
float threshold= 1.0;// 9
int cellSize = 50;//    8
float scaler = 15.0; // multiplier size of surrounding shapes
color cellColor = (#FFFFFF);// highlight cell color 
PShape pblob;

int [] cellTime = new int [(800*800)];// current lifetime of a cell (milliseconds)
float [] cell = new float[(800*800)];// store whatever value needed
float [] hueC = new float[(800*800)];// used for temporarily storing pixel propertie
float [] satC = new float[(800*800)];// 
float [] briC = new float[(800*800)];//
int [] xPos = new int[(800*800)];//
int [] yPos = new int[(800*800)];//

int counter;
float hT; // temp rgb
float sT;
float bT;
float check;
int sumX, sumY;
int countCells;// counts the cells that are above the threshold
float posX, posY;

float easing = 0.3;// target rect + seeker easing default = 0.3
float easex, easey;

// agents
int agents = 16;
float []direction = new float[agents];
PVector []location = new PVector[agents];
PVector []speed = new PVector[agents];
float []interval = new float[agents];
float []centerD = new float[agents];

float []easingA = new float[agents];
float [] easexA = new float[agents];
float [] easeyA = new float[agents];

//text
String str1 = "Biomodd Bruges is a culture, a home and a host for microorganisms";

void setup() {
  //frameRate(8); // reducing fps eliminates some artifacts
  //size(640, 480);
  size(800, 800); 
  surface.setLocation(-1920, 0);
  font = createFont("CircularStd-Bold.ttf", 64);
  textFont(font);

  strokeWeight(0.3);
  
  String[] cameras = Capture.list();

  // creates a Triangle pshape used for agents.
  pblob = createShape(TRIANGLE, 10, 0, -5, 5, -5, -5);
  pblob.setFill(color(#000000));
  pblob.setStroke(false);
  pblob.scale(1);

  // initial 'random' positions for agents.
  for (int i=0; i<agents; i++) {

    location[i] = new PVector(400.0, 400.0);
    //speed = new PVector(random (-.8, .8), -.5);
    speed[i] = new PVector(random(0.1, 3.0), random(0.1, 3.0));

    easexA[i] = random(0, 400);
    easeyA[i] = random(0, 400);
    easingA[i] = random(0.001, 0.005);
  }

  // check for webcam presence
  if (cameras.length == 0) {
    println("No cameras.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0, width, height);

  //filter1();// hue
  filter(GRAY);
  filter2();// saturation + read/store cell values

  //filter3();// brightness: merges moving objects with background 0 or 1
  if (solidBackground == true) { 
    background(#000000);
    dish();
  } 

  makeCells();
  easing();
  cellTime();
  //seeker();
  //agents();
  //web();
  //seeker();

  text();
  if (UI == true) {
    overlay();
  }
}

// displays cells or shape for a 'lifespan' amount of time before dissapearance
void cellTime() {

  int z = 16;//amount of cells edge(800/ cellSize);



  for (int i=0; i< ((z)*(z)); i++) {

    int startTime = cellTime[i];

    if ((millis() - startTime) < lifeSpan) {

      if (inverter == true) {

        noFill();
        square(xPos[i], yPos[i], cellSize);
      } else fill(#FFFFFF);


      strokeWeight(1);
      stroke(#000000);
      //circle(xPos[i], yPos[i], 30);
      square(xPos[i], yPos[i], cellSize);
    } else if (inverter == true) {

      fill(#000000);
      square(xPos[i], yPos[i], cellSize);
    }
  }
}

void easing() {
  // easing rect
  float targetX = posX;
  float targetY = posY;
  float dx = targetX - easex;
  float dy = targetY - easey;
  easex += dx * easing;
  easey += dy * easing;
  //fill(#0000FF);
  //square(easex, height/2, 20);
  //square(easex, easey, 20);
}

void seeker() {
  if (hit == true) {
    pblob.setFill(false);
  } else pblob.setFill(true);

  PVector pv = new PVector(posX-easex, posY-easey);
  pblob.scale(2);

  pushMatrix();
  translate (easex, easey);
  rotate(pv.heading());
  //virus();
  //pblob.setFill(color(#000000));
  shape(pblob, 0, 0);
  popMatrix();
  pblob.scale(1.0/2.0);
}

void highliteCells(float transx, float transy, PVector newpv) {
  //fill(cellColor);// cell color
  noFill();
  strokeWeight(1.0);
  stroke(cellColor);
  //noStroke();
  pushMatrix();
  translate (transx, transy);
  // pointing triangles
  //rotate(newpv.heading());// rotate cells according to heading
  //scaler = random (-15.0, 15.0);// 'random' sized scale
  //triangle(10+scaler, 0, -5, 5+scaler, -5, -5-scaler);// pointy end at 90deg
  //circle(0, 0, scaler);
  // fill(#00FF00);
  square(0, 0, cellSize);

  popMatrix();
}

void agents() {

  for (int i=0; i<agents; i++) {
    //PVector pv = new PVector(easex-location[i].x, easey -location[i].y);// following seeker:pvectors: location + pv = mouse
    PVector pv = new PVector(posX-location[i].x, posY -location[i].y);// following target: pvectors: location + pv = mouse

    if (hit == true) {

      PVector target = new PVector(easex, easey);
      location[i].lerp(target, 0.01+(0.005*i));// * t gives each agent a unique lerp speed

      //location[i].add(pv);// LEAVE LINE HERE FOR INFO: adds x and y components to location, so it will become location[i] (x and y)
    } else {

      interval[i] = int (random (0, 8)); // temp substitute for random time
      if (interval[i] == 1) { 
        direction[i] =20*(random(-(TWO_PI/360), (TWO_PI/360)));
        speed[i].rotate(direction[i]);
      }
      location[i].add(speed[i]);
    }

    centerD[i] = dist(width/2, height/2, location[i].x, location[i].y);
    if (centerD[i]> 345-((5.0+i)/2.0)) {
      speed[i].rotate(direction[i]+PI);
      PVector target = new PVector(width/2.0, height/2.0);
      location[i].lerp(target, 0.01+(0.005*i));
    } 

    // connect to all nodes
    stroke(#EEEEEE);
    strokeWeight(0.1);
    for (int l=0; l<agents; l++) {    
      line(location[i].x, location[i].y, location[l].x, location[l].y);
    }

    // render agents
    pushMatrix();
    translate(location[i].x, location[i].y);

    if (hit == true) {
      rotate(pv.heading());
    }
    if (hit == false) {
      rotate(speed[i].heading());
    }

    fill(#000000);
    noStroke();
    triangle(0, -1-(i/3), 2+i, 0, 0, 1+(i/3));
    popMatrix();
  }
}


void virus() {

  fill(#000000);
  noStroke();
  for (int i = 0; i < 360; i=i+5) {
    rotate ((TWO_PI/360)*5);
    // fill(#000000);
    float rnd = random(38, 40);
    line (rnd-8, 0, rnd, 0);
    circle(rnd-8, 0, random(3.0, 7.0) );
    circle(rnd, 0, random(1.0, 3.0));

    float rnd2 = random(20, rnd-8);
    //line (0, 0, rnd, 0);
    circle (rnd2, 0, 3);
    float rnd3 = random(10, rnd2);
    // circle(rnd3, 0, random(5.0, 7.0));
    circle (rnd3, 0, 2);
  }
}

void dish() {
  fill(#FFFFFF);
  strokeWeight(1);
  circle (width/2, height/2, 700);
}

void web() {

  stroke(#FFFFFF);
  noFill();
  line(0, 0, posX, posY);
  line(width, 0, posX, posY);
  line(width, height, posX, posY);
  line(0, height, posX, posY);
}

// saturation  s=0
void  filter2() {
  loadPixels();//
  colorMode(HSB, 360, 100, 100); // saturation scale, leave at 100 for direct control
  for (int i = 0; i < (width*height); i++) {
    h = round(hue(pixels[i]));
    s = round(saturation(pixels[i]));
    b = round(brightness(pixels[i]));
    //if (s<50) {
    //  s=0;
    //} else {     
    //  s=100;
    //}
    pixels[i]   = color(h, 100, b);// saturation on level of 100. why:if s=0, h becomes 0 when read!
  }
  // updatePixels();
}

// brightness b=0 or b=100
void  filter3() { 
  loadPixels();//
  colorMode(HSB, 360, 100, 100); 
  for (int i = 0; i < (width*height); i++) {
    h = round(hue(pixels[i]));
    s = round(saturation(pixels[i]));
    b = round(brightness(pixels[i]));

    if (b<30) {
      b=0;
    } else {     
      b=100;
    }
    pixels[i]   = color(h, s, b);
    //pixels[i]   = color(0, 0, 0); // try fixed values for s,b
  }
  updatePixels();// only for viewing videostream
}

void makeCells() {
  colorMode(HSB, 360, 100, 100);// 

  for (int row=0; row < height-cellSize+1; row = row + cellSize) {

    for (int column=0; column < width; column=column+cellSize) {
      // println("____________line:",column);

      // horizontal scan pixelSize
      for (int y=0; y<cellSize; y++) {
        // horizontal scan pixelSize
        for (int x=0; x<cellSize; x++) {

          int pos = column+x+(width*y)+(width*row);
          //  float rT = pixels[pos];
          hT = hT + hue(pixels[pos]);
          sT = sT + saturation(pixels[pos]);
          bT = bT + brightness(pixels[pos]);
          //  pixels[pos] = color(h, s, b);
        }// end horizontal
      }// end vertical


      counter++;
      // calculating average HSB values within a cell
      hT=hT/(cellSize*cellSize);
      sT=sT/(cellSize*cellSize);
      bT=bT/(cellSize*cellSize);

      // pushMatrix();
      // translate (column, row);

      // calculating the H-B difference
      float diff = abs(hT-bT)-abs(hueC [counter]-briC [counter]);// based on hue and brightnes. S is fixed. 
      //float check = abs(bT-briC [counter]);// based on brightness only

      xPos[counter] = column;
      yPos[counter] = row;

      if ( diff > threshold) {

        //xPos[countCells] = column;//  use the variable 'counter' : the array must loop through all the cells on the screen later.
        //yPos[countCells] = row;
       
        sumX = sumX + column;
        sumY = sumY +row;
        countCells++;// counts the cells that are above the threshold
        cellTime[counter] = millis();
      } 


      //popMatrix();
      hueC [counter]=  hT;
      satC [counter]=  sT;// sat = 0 when using gray filter
      briC [counter]=  bT;

      hT=0;
      sT=0;
      bT=0;

      // view cell matrix
      if (viewmatrix == true) {
        strokeWeight(1.0);
        //stroke(#FFFFFF);
        stroke(#000000);
        noFill();
        square(row, column, cellSize);

        //viewMatrix();
      }
    }
  }

  // drawing target rect
  if (countCells !=0) {
    // drawning target rectangle+ bat, outside of this loop, for less flicker-more updates
    posX=(sumX/countCells);
    posY=(sumY/countCells);
    sumX = 0;
    sumY = 0;
    //countCells=0;
  }


  // render shapes from array. Amount= countCells
  for (int i=0; i < countCells; i++) {

    //// show connecting lines if seeker is at center
    //if (hit == true) {
    //  strokeWeight(1);
    //  stroke(#FF0000);
    //  line (posX, posY, xPos[i], yPos[i]);
    //}

    PVector pv = new PVector(posX-xPos[i], posY-yPos[i]);

    // check the distance between center of area (agents) and the seeker. If < x, it's a 'hit'.
    // 'hit' can be used for ...
    float targetD =  dist(easex, easey, posX, posY);
    if (targetD < 30) {
      hit = true;
    } else hit = false;//pblob.scale(2.0);



    //  highliteCells(xPos[i], yPos[i], pv);
  }
  counter=0;
  countCells=0;
}


//void viewMatrix() {
//  stroke(#999999);
//  noFill();
//  square(0, 0, cellSize);
//}

void overlay() {
  textAlign(LEFT);
  textSize(12);
  fill(#00FFFF);
  text("T:"+day()+"/"+month()+"/"+year(), 20, 20);
  text("C:Clearscreen   M:Matrix   T:Targetrect   U:UI", 130, 20);
  text("FPS:" + frameRate, 20, 40);
  text("cellSize: " + cellSize, 20, 60);
  text("lifespan: " + lifeSpan, 20, 80);
  text("Threshold: " + threshold, 20, 100);
  text("Hit: "+hit, 20, 120);
  //text(" Brightness Cutoff: "+brightnessCutoff, 20, 100);
  //text(" Check: "+check, 20, 120);

  if (targetRect == true) {
    // target rect + bat
    strokeWeight(2.0);
    stroke(#00FF00);
    //fill(#FF0000);
    noFill();
    //   square(posX, posY, cellSize);
    square(easex, easey, cellSize);
    rect (easex, height-20, 60, 20);
    rect (0, easey-30, 20, 60);
  }
}

void text() {
  textAlign(CENTER);
  textSize(20);
  fill(0);
  text (str1, width/2, height/2);
}



void keyPressed() {
  final int k = keyCode;

  if (k == 'S') saveFrame("save-###.png");
  if (k == LEFT ) {
    threshold = threshold - 0.1;
  }
  if (k == RIGHT ) {
    threshold = threshold + 0.1;
  }
  if (k == UP ) {
    cellSize = cellSize + 1;
  }
  if (k == DOWN ) {
    cellSize = cellSize - 1;
    if (cellSize <4) {
      cellSize=4;
    }
  }
  if (k == 'M') { 
    if (viewmatrix == true) {
      viewmatrix= false;
    } else viewmatrix=true;
  }
  if (k == 'C') { 
    if (solidBackground == true) {
      solidBackground= false;
    } else solidBackground=true;
  }
  if (k == 'T') { 
    if (targetRect == true) {
      targetRect= false;
    } else targetRect = true;
    // else         noLoop();
  }
  if (k == 'U') { 
    if (UI == true) {
      UI= false;
    } else UI = true;
    // else         noLoop();
  }
  if (k == 'I') { 
    if (inverter == true) {
      inverter= false;
    } else inverter = true;
    // else         noLoop();
  }
}
