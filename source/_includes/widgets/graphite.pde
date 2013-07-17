int graphiteCount = 0;
int graphiteTempCount = 0;
int statsdCount = 0;
int actualEventCount = 0;
int i = 0;

void setup() {
  size(400,400);
  frameRate(1);
}

void drawGraphiteBuffer() {
  fill(#0000FF);
  rect(width/3 * 2, 0, width/3 , height/3);
  fill(#000000);
  text("Graphite Buffer", width/3*2 + 10, 20);
  textSize(24);
  text( graphiteTempCount, width - width/6 - textWidth(str(graphiteTempCount))/2, height/6 + 12);
}

void drawArrows() {
  fill(#dddddd);
  triangle(width/2 - 20, height/3 * 2, width / 2 + 20, height/3 * 2, width/2, height/ 3 * 2 - 20);
  triangle(width - width/6 - 20, height/3, width - width/6 + 20, height/3, width - width/6, height/3 - 20);
  triangle(width/3*2, height/6 + 20, width/3*2, height/6 - 20, width/3*2 - 20, height/6); 
}
void statBox(color color1, color color2, int yoffset, String label, int value) {
  fill(color1);
  rect(0, yoffset, width, height/3);
  fill(color2);
  textSize(24);
  text(value, width/2 - textWidth(str(value))/2, yoffset + (height/3)/2 + 12);
  textSize(12);
  text(label, 10, 20 + yoffset);
  fill(#cccccc);
}


void flushStatsd() {
  graphiteTempCount = statsdCount;
  statsdCount = 0;
}

void writeGraphiteCount() {
  graphiteCount += graphiteTempCount;
  graphiteTempCount = 0;
}

void draw() {

  if (i > 0 && i % statsdFlushRate == 0) {
    statBox(#00FF00, 000000, (height/3), "Statsd (FLUSHING)", statsdCount);
    flushStatsd();
  }
  else {
    statBox(#FFFFFF, 000000, (height/3), "Statsd", statsdCount);
  }
  
  if (i>0 && i % graphiteStorageInterval == 0) {
    statBox(#00FF00, #000000, 0, "Graphite (WRITING FROM BUFFER TO DISK)", graphiteCount);
    writeGraphiteCount();
  }
  else {
     statBox(#000000, #FFFFFF, 0, "Graphite (on disk)", graphiteCount);
  }
    
  statBox(#000000, #FFFFFF, (height/3)*2, "Actual Event Count", actualEventCount);
  drawGraphiteBuffer();
  drawArrows();
  
  statsdCount += eventRate;
  actualEventCount += eventRate;

  i++;
}
