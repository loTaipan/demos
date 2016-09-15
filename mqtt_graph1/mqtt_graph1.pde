import mqtt.*;
import java.text.*;
import java.util.Date;

final boolean DEBUG = true;

final String MQTT_BROKER_URI = "mqtt://staging.thethingsnetwork.org:1883";
final String MQTT_USER = "70B3D57ED0000DC2";
final String MQTT_PASSWORD = "1iULIOYIWsd1Wn2KSRxAzE5m0Xfv17dyo0/D/duktEM=";  
final String MQTT_CLIENT_ID = "myclientid_" + random( 0, 100 );
final String MQTT_SUBSCRIPTION_00 = "+/devices/+/up";
final String MQTT_SENSOR_00_ATTRIB = "temperature";
final int MAX_RECORD_COUNT = 100;

final float SENSOR_0_VALUE_SCALE = 1.0f;//20.0f;
final float SENSOR_0_UNNORMALIZED_MIN = 10.0f;
final float SENSOR_0_UNNORMALIZED_MAX = 30.0f;

final int COLOR_BG = 0x11;
final int COLOR_TXT_FILL = 0xCC;
final int COLOR_FG = COLOR_TXT_FILL;

final String TXT_TITLE = "Limmat Fühler";
final String TXT_SENSOR_00 = "Temperatur [°C]";
final String TXT_X_AXIS = "Zeit";
//final String TXT_SENSOR_01 = "foo";
final String TXT_FONT_LARGE = "NotoSans-48.vlw";
final String TXT_FONT_SMALL = "NotoSans-23.vlw";
final int TXT_FONT_SIZE_LARGE = 48;
final int TXT_FONT_SIZE_SMALL = 23;

final float MARGIN_X = 50.0f;
final float PXL_GAP =  5.0f;
//final float BAR_WIDTH = 30.0f;
float BAR_HEIGHT = 400.0f;


class CRecord
{
  public CRecord( float v, Date d )
  {
    this.m_fValue = v;
    this.m_oDate = new Date( d.getTime() );
  }
  public float m_fValue;
  public Date m_oDate;
}

float getTimeValue( Date oDate ) {
  return oDate.getHours() +
    ( oDate.getMinutes() + oDate.getSeconds() / 60.0f ) / 60.0f;
}


void addRecord( float v, Date d )
{
  g_oaRecord.add( 0, new CRecord( v, d ) );
  
  if( v > g_fSensor0Max )
    g_fSensor0Max = v;
  if( v < g_fSensor0Min )
    g_fSensor0Min = v;
}


MQTTClient g_oMQTTClient;
ArrayList<CRecord> g_oaRecord;
PFont g_oFontLarge, g_oFontSmall;
float g_fSensor0Min = Float.MAX_VALUE, g_fSensor0Max = -Float.MAX_VALUE;
boolean g_bDoNormalize = true;

void setup()
{
  //fullScreen( 1 ); // uncomment to run sketch in fullscreen mode
  size( 1280, 1024 ); // comment out for fullscreen mode
  
  BAR_HEIGHT = height * 0.8f;
  
  if( !DEBUG )
  {
    g_oMQTTClient = new MQTTClient( this );
    g_oMQTTClient.connect( MQTT_BROKER_URI, MQTT_CLIENT_ID, true, MQTT_USER, MQTT_PASSWORD );
    g_oMQTTClient.subscribe( MQTT_SUBSCRIPTION_00 );
  }
  
  g_oaRecord = new ArrayList();
  if( DEBUG ) {
    Date oDate = new Date();
    int iM = oDate.getMinutes();
    for( int i=0; i<MAX_RECORD_COUNT; ++i ) {
      //println( "debug: " + oDate );
      addRecord( random( 10.0f, 30.0f ), oDate );
      oDate.setMinutes( iM );
      --iM;
      if( iM < 0 )
      {
        oDate.setHours( oDate.getHours() - 1 );
        iM = 59;
      }
    }
  }
  
  g_oFontLarge = loadFont( TXT_FONT_LARGE );
  g_oFontSmall = loadFont( TXT_FONT_SMALL );
}


void draw()
{
  background( COLOR_BG );
  
  if( g_oaRecord.isEmpty() )
    return;
  
  //float fX = MARGIN_X; // width - fMarginX;
  float fY = 50.0f;
  
  float fTop, fBottom;
  if( g_bDoNormalize )
  {
    fTop = g_fSensor0Max;
    fBottom = g_fSensor0Min;
  }
  else
  {
    fTop = SENSOR_0_UNNORMALIZED_MAX;
    fBottom = SENSOR_0_UNNORMALIZED_MIN;
  }
  final String sValueTop = String.format( "%1$.1f", fTop );
  final String sValueBottom = String.format( "%1$.1f", fBottom );
  
  //scale( width / 800.0f, height / 600.0f ); // hack
  
  final String sTitle = TXT_TITLE
    + String.format( " %1$04d-%2$02d-%3$02d", year(), month(), day() );
  fill( COLOR_TXT_FILL );
  textAlign( LEFT );
  textFont( g_oFontLarge );
  text( sTitle, MARGIN_X, fY );
  fY += TXT_FONT_SIZE_LARGE * 1.5f;
  
  textFont( g_oFontSmall );
  textAlign( CENTER );
  pushMatrix();
    rotate( -PI / 2 );
    translate( -fY - BAR_HEIGHT / 2, MARGIN_X - PXL_GAP * 2 ); // -MARGIN_X );
    text( TXT_SENSOR_00, 0, 0 ); //MARGIN_X, fY );
    textAlign( RIGHT );
    text( sValueTop, BAR_HEIGHT / 2, 0 );
    textAlign( LEFT );
    text( sValueBottom, -BAR_HEIGHT / 2, 0 );
  popMatrix();
  textAlign( LEFT );
  text( TXT_X_AXIS, width/2, fY + BAR_HEIGHT + TXT_FONT_SIZE_SMALL + PXL_GAP * 4 );
  
  //textAlign( RIGHT );
  //textFont( g_oFontSmall );
  //text( fTop, width - MARGIN_X - PXL_GAP, fY - PXL_GAP );
  //text( fBottom, width - MARGIN_X - PXL_GAP, fY + BAR_HEIGHT - PXL_GAP );
  
  
  final Date oNow = new Date();
  final float fTNow = getTimeValue( oNow );
  
  final int iHRight = oNow.getHours();
  final int iHLeft = ( iHRight == 0 ? 23 : iHRight - 1 ); // 1 hour
  final int iM = oNow.getMinutes();
  final String sTimeLeft = String.format( "%1$02d:%2$02d", iHLeft, iM );
  final String sTimeRight = String.format( "%1$02d:%2$02d", iHRight, iM );
  textAlign( LEFT );
  text( sTimeLeft, MARGIN_X, fY + BAR_HEIGHT + TXT_FONT_SIZE_SMALL + PXL_GAP * 4 );
  textAlign( RIGHT );
  text( sTimeRight, width - MARGIN_X, fY + BAR_HEIGHT + TXT_FONT_SIZE_SMALL + PXL_GAP * 4 );
  
  
  
  final float GRAPH_X_MIN = MARGIN_X;
  final float GRAPH_X_MAX = width - MARGIN_X;
  final float GRAPH_X_WIDTH = GRAPH_X_MAX - GRAPH_X_MIN;
  
  noFill();
  stroke( COLOR_FG );
  strokeWeight( 2.0f );
  strokeJoin( ROUND );
  strokeCap( ROUND );
  //final float[] afDash = new float[]{7, 7} ;
  //dashline( MARGIN_X, fY, width - MARGIN_X, fY, afDash );
  //dashline( MARGIN_X, fY + BAR_HEIGHT, width - MARGIN_X, fY + BAR_HEIGHT, afDash );
  //line( MARGIN_X, fY, width - MARGIN_X, fY );
  line( GRAPH_X_MIN, fY + BAR_HEIGHT, GRAPH_X_MAX, fY + BAR_HEIGHT ); // horizontal
  line( GRAPH_X_MIN, fY + BAR_HEIGHT, GRAPH_X_MIN, fY ); // vertical
  
  final int iMinute = oNow.getMinutes();
  for( int m=0; m<=60; ++m )
  {
    final int mm = iMinute + m;
    final float fLength = ( mm % 5 != 0 ? 5.0f : ( mm % 15 != 0 ? 10.0f : 15.0f ) );
    final float fXX = GRAPH_X_MIN + m * GRAPH_X_WIDTH / 60;
    final float fYY = fY + BAR_HEIGHT;
    line( fXX, fYY, fXX, fYY + fLength );
  }
  
  final float fDiff = ( g_fSensor0Max - g_fSensor0Min );
  final float fVNormFac = ( fDiff <= 0.0f ? 1.0f : 1.0f / fDiff );
  final float fBarWidth = ( width - 2 * MARGIN_X ) / ( g_oaRecord.size() );
  
  //fill( 0xAA );
  //noStroke();
  noFill();
  stroke( COLOR_FG );
  strokeWeight( 2.0f );
  strokeJoin( ROUND );
  beginShape();
  for( CRecord oR : g_oaRecord )
  {
    float fV = oR.m_fValue;
    
    if( g_bDoNormalize )
    {
      fV -= g_fSensor0Min;
      fV *= fVNormFac;
      fV *= BAR_HEIGHT;
    }
    else
    {
      fV -= SENSOR_0_UNNORMALIZED_MIN;
      fV *= ( BAR_HEIGHT / SENSOR_0_UNNORMALIZED_MAX );
    }
    //fV = BAR_HEIGHT - fV;
    
    final float fT = ( fTNow - getTimeValue( oR.m_oDate ) );
    if( fT < 0.0f || fT > 1.0f )
      continue;
    
    float fX = GRAPH_X_MIN + ( GRAPH_X_WIDTH * ( 1.0f - fT ) );
    vertex( fX, fY + fV );
    //rect( fX , fY, BAR_WIDTH, oR.m_fValue * BAR_HEIGHT );
    //fX += fBarWidth; //BAR_WIDTH;
  }
  endShape();
}


void keyPressed()
{
  g_bDoNormalize = !g_bDoNormalize;
}


void messageReceived( String sTopic, byte[] abPayload ) //, int qos, boolean retained )
{
  String sData = new String( abPayload );
  println( "message: " + sTopic + " - " + sData );
  
  JSONObject oJSON = parseJSONObject( sData );
  if( oJSON != null )
  {
    final JSONObject oFields = oJSON.getJSONObject( "fields" );
    final float fValue = oFields.getFloat( MQTT_SENSOR_00_ATTRIB ) * SENSOR_0_VALUE_SCALE;
    if( g_oaRecord.size() >= MAX_RECORD_COUNT )
      g_oaRecord.remove( g_oaRecord.size() - 1 );
    
    /*
    final JSONArray oMetaDataArray = oJSON.getJSONArray( "metadata" );
    final JSONObject oMetaData = oMetaDataArray.getJSONObject( 0 );
    final String sServerTime = oMetaData.getString( "server_time" );
    //final String[] sServerTimeSplit = sServerTime.split( "T" );
    //final String sDate = sServerTimeSplit[0];
    //final String sTime = sServerTimeSplit[1];
    //final String[] sTimeHMS = sTime.split( ":" );
    Date oDate = null;
    try {
      oDate = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS").parse( sServerTime );
      println( "Date: " + oDate );
    }
    catch( ParseException e ) {
      println( "EXCEPTION: " + e.getMessage() );
    }
    */
    addRecord( fValue, new Date() );
  }
}



// ref.: https://processing.org/discourse/beta/num_1202486379.html
/* 
 * Draw a dashed line with given set of dashes and gap lengths. 
 * x0 starting x-coordinate of line. 
 * y0 starting y-coordinate of line. 
 * x1 ending x-coordinate of line. 
 * y1 ending y-coordinate of line. 
 * spacing array giving lengths of dashes and gaps in pixels; 
 *  an array with values {5, 3, 9, 4} will draw a line with a 
 *  5-pixel dash, 3-pixel gap, 9-pixel dash, and 4-pixel gap. 
 *  if the array has an odd number of entries, the values are 
 *  recycled, so an array of {5, 3, 2} will draw a line with a 
 *  5-pixel dash, 3-pixel gap, 2-pixel dash, 5-pixel gap, 
 *  3-pixel dash, and 2-pixel gap, then repeat. 
 */ 
void dashline(float x0, float y0, float x1, float y1, float[ ] spacing) 
{ 
  float distance = dist(x0, y0, x1, y1); 
  float [ ] xSpacing = new float[spacing.length]; 
  float [ ] ySpacing = new float[spacing.length]; 
  float drawn = 0.0;  // amount of distance drawn 
 
  if (distance > 0) 
  { 
    int i; 
    boolean drawLine = true; // alternate between dashes and gaps 
 
    /* 
      Figure out x and y distances for each of the spacing values 
      I decided to trade memory for time; I'd rather allocate 
      a few dozen bytes than have to do a calculation every time 
      I draw. 
    */ 
    for (i = 0; i < spacing.length; i++) 
    { 
      xSpacing[i] = lerp(0, (x1 - x0), spacing[i] / distance); 
      ySpacing[i] = lerp(0, (y1 - y0), spacing[i] / distance); 
    } 
 
    i = 0; 
    while (drawn < distance) 
    { 
      if (drawLine) 
      { 
        line(x0, y0, x0 + xSpacing[i], y0 + ySpacing[i]); 
      } 
      x0 += xSpacing[i]; 
      y0 += ySpacing[i]; 
      /* Add distance "drawn" by this line or gap */ 
      drawn = drawn + mag(xSpacing[i], ySpacing[i]); 
      i = (i + 1) % spacing.length;  // cycle through array 
      drawLine = !drawLine;  // switch between dash and gap 
    } 
  } 
}