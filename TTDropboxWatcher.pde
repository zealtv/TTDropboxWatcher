import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

XML xml;
XML datebuffer;
String[] camStrings = new String[4];
int[] camVals = new int[4];
Date[] camDates = new Date[4];
boolean[] camAlive = new boolean[4];

Date now;
DateFormat gmtFormat;
DateFormat localFormat;
DateFormat shortLocalFormat;
DateFormat timeFormat;
DateFormat leidenFormat;
DateFormat shortLeidenFormat;

boolean loading = false;
boolean doLocalTime = true;



void setup()
{
  size( 600, 250 );
  smooth();
  colorMode( HSB, 360, 100, 100, 100 );

  xml = loadXML("https://www.dropbox.com/431762015/930111844/3Zl_yUJJGvPfm6JGlv0E24i9t6AXLQ0zPElIVSX2/events.xml");
  //saveXML( xml, "feed.xml" );
  //datebuffer = loadXML("datebuffer.xml");

  File file = new File( sketchPath("datebuffer.xml") );
  if ( file.exists() )
  {
    println("Loading datebuffer.xml");
    datebuffer = loadXML("datebuffer.xml");
  } 
  else
  {
    println("Creating datebuffer.xml");
    datebuffer = new XML("datebuffer");
  
    datebuffer.addChild( "CAM1" );
    datebuffer.getChild( "CAM1" ).setContent( "0" );
    datebuffer.addChild( "CAM2" );
    datebuffer.getChild( "CAM2" ).setContent( "0" );  
    datebuffer.addChild( "CAM3" );
    datebuffer.getChild( "CAM3" ).setContent( "0" );  
    datebuffer.addChild( "CAM4" );
    datebuffer.getChild( "CAM4" ).setContent( "0" );
  
    saveXML( datebuffer, "datebuffer.xml" );
  }

  for( int i = 0; i < 4; i++ )
  {
    camStrings[i] = "0";
    camVals[i] = -1;
    camDates[i] = new Date();
    camAlive[i] = false;
  }

  now = new Date();

  gmtFormat = new SimpleDateFormat( "EEE, d MMM yyyy HH:mm:ss zzz" );
  gmtFormat.setTimeZone( TimeZone.getTimeZone("GMT") );

  localFormat = new SimpleDateFormat( "d MMMM, HH:mm:ss zzz" );
  localFormat.setTimeZone( TimeZone.getDefault() );
  
  shortLocalFormat = new SimpleDateFormat( "d MMMM\n HH:mm:ss" );
  shortLocalFormat.setTimeZone( TimeZone.getDefault() );
  
  leidenFormat = new SimpleDateFormat( "d MMMM, HH:mm:ss" );
  shortLeidenFormat = new SimpleDateFormat( "d MMMM\n HH:mm:ss" );  
  TimeZone tz = TimeZone.getTimeZone("GMT+2");
  tz.setID("CEST");
  //leidenFormat = new SimpleDateFormat( "d MMM HH:mm:ss" );
  leidenFormat.setTimeZone( tz );
  shortLeidenFormat.setTimeZone( tz );


  timeFormat = new SimpleDateFormat( "" );


  println( "now : " + gmtFormat.format(now) );
  
  loadData();
}




void loadData()
{
  
  XML[] children = xml.getChildren("channel/item");
  
  
  
  for( int i = children.length - 1; i >= 0; i-- )
  {    
    String date = children[i].getChildren("pubDate")[0].getContent();
    String description = children[i].getChildren("description")[0].getContent();
    //need to check this is not going into the sorting folder..  might not be possible...
    
    
    for( int j = 0; j < 4; j++ )
    {
      String s = "CAM" + (j + 1);
      String[] check = match(description, s);
     
      if( check != null )
      {
        

        getVal(date, j);
        camStrings[j] = date;
        camAlive[j] = true;

        
        datebuffer.getChild(s).setContent( date );
        
        saveXML( datebuffer, "datebuffer.xml" );
      }
    }    
  }
  
  
}





void draw()
{
  
  //clear();
  background( 50 );
  textSize( 16 );
  textAlign( CENTER, CENTER );

  pushMatrix();
  pushStyle();
  textSize(42);
  
  String nowString;
  
  if( doLocalTime ) nowString = localFormat.format( now );
  else nowString = leidenFormat.format( now ) + " CEST";
  
  text( nowString, width/2, height/12 );
  //text( shortLeidenFormat.format( now ) + " CEST", width/2, height - height/10 );
  popStyle();
  popMatrix();
  
  pushMatrix();
  translate(width/8,height/2 + 20 );
  

  
  
  for(int i = 0; i < 4; i++)
  {
    if( camAlive[i] )
    {

      int eColor = (int)map( camVals[i], 100, 20, 0, 100 );
      eColor = max( 0, eColor );
      eColor = min( 100, eColor );

      fill( eColor, 100, 100, 100);

      int eSize = (int)map( camVals[i], 100, 10, 30, 80 );
      eSize = max(30, eSize);
      eSize = min(80, eSize);


      ellipse(0,0, eSize, eSize);
      
      fill( 0, 0, 100, 100 );
      text( i + 1, 0, 0 );
      
    
      fill( 0, 0, 100 );
      if(doLocalTime)
      {
        text( shortLocalFormat.format( camDates[i] ), 0, -height/3.8 );
      }
      else
      {        
        text( shortLeidenFormat.format( camDates[i] ), 0, -height/3.8 );
      }
 

      pushStyle();
      textSize(12);
      text( "last activity was\n" + getTimeElapsed( camDates[i] ) + " ago", 0, height/4 );
      popStyle();
      
    }
    else  
    {
      pushStyle();
      textSize(40);
      //stroke(0, 0, 100);
      fill(0, 0, 100);
      text( "?", 0, 0 ); 
      popStyle();
    }
    translate(width/4, 0);
  }
  popMatrix();

  calcVals();

  //check for new rss
  if( frameCount % 200 == 0 ) 
  {
    if( !loading ) thread( "reloadData" ); 
  }

}




 String getTimeElapsed( Date c )
 {
    long seconds = ( now.getTime() - c.getTime() ) / 1000;

    int day = (int)TimeUnit.SECONDS.toDays(seconds);        
    long hours = TimeUnit.SECONDS.toHours(seconds) - (day *24);
    long minute = TimeUnit.SECONDS.toMinutes(seconds) - (TimeUnit.SECONDS.toHours(seconds)* 60);
    long second = TimeUnit.SECONDS.toSeconds(seconds) - (TimeUnit.SECONDS.toMinutes(seconds) *60);

    String returnString = "";

    if( day == 1 )
    {
      returnString += day + " day "; 
    }
    else 
    {
      returnString += day + " days ";  
    }
      

    returnString += nf((int)hours, 2) + ":" + nf((int)minute, 2) + ":" + nf((int)second,2);
    return returnString;
 }








void getVal( String s, int j )
{

  now = new Date();

  try 
  {
    camDates[j] = gmtFormat.parse( s );
    int diff = (int) ( now.getTime() - camDates[j].getTime() )/1000;

    camVals[j] = diff;
  }
  catch (Exception e) 
  {
    println( "no last known date: CAM" + (j + 1) );

  }
    
}





void calcVals()
{
  now = new Date();

  for( int i = 0; i < 4; i++ )
  { 
    if(camAlive[i])
    {
      camVals[i] = (int) ( now.getTime() - camDates[i].getTime() )/1000;
    }
  }
}






void reloadData()
{
  loading = true;
  //saveXML( datebuffer, "datebuffer.xml" );
  xml = loadXML("https://www.dropbox.com/431762015/930111844/3Zl_yUJJGvPfm6JGlv0E24i9t6AXLQ0zPElIVSX2/events.xml");
  
  loadBuffer();
  loadData();
  
  print(".");
  loading = false;
}





void loadBuffer()
{
  for( int j = 0; j < 4; j++ )
    {
      String s = "CAM" + (j + 1);
      XML c = datebuffer.getChild( s ); 
     
      String date = c.getContent();

      if( date != "0" )
      {
        getVal(date, j);
        camStrings[j] = date;
        camAlive[j] = true;
      }
      else
      {
        println("no last seen data for CAM" + ( j + 1 ) );
      }
    } 
}


void mouseClicked() {
  doLocalTime = !doLocalTime;
}
