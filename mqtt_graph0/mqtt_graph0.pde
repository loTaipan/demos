import mqtt.*;

final String MQTT_BROKER_URI = "mqtt://staging.thethingsnetwork.org:1883";
final String MQTT_USER = "70B3D57ED0000DC2";
final String MQTT_PASSWORD = "1iULIOYIWsd1Wn2KSRxAzE5m0Xfv17dyo0/D/duktEM=";  
final String MQTT_CLIENT_ID = "myclientid_" + random( 0, 100 ); //"70B3D57ED0000DC2";
final String MQTT_SUBSCRIPTION_00 = "+/devices/+/up";
final String MQTT_SENSOR_00_ATTRIB = "temperature";
final int MAX_RECORD_COUNT = 100;

final float SENSOR_0_VALUE_SCALE = 1.0f; //20.0f;
final float SENSOR_0_UNNORMALIZED_MIN = 10.0f;
final float SENSOR_0_UNNORMALIZED_MAX = 30.0f;

final int TXT_FILL = 0xAA;
final int COLOR_FG = TXT_FILL;

final String TXT_TITLE = "limatt fühler";
final String TXT_SENSOR_00 = "temperature";
//final String TXT_SENSOR_01 = "foo";
final String TXT_FONT_LARGE = "NotoSans-48.vlw";
final String TXT_FONT_SMALL = "NotoSans-23.vlw";
final int TXT_FONT_SIZE_LARGE = 48;
final int TXT_FONT_SIZE_SMALL = 23;

final float MARGIN_X = 30.0f;
final float PXL_GAP =  5.0f;
//final float BAR_WIDTH = 30.0f;
final float BAR_HEIGHT = 300.0f;


class CRecord
{
  public CRecord( float v, int t )
  {
    this.m_fValue = v;
    this.m_iTime = t;
  }
  public float m_fValue  ;
  public int m_iTime;
}


MQTTClient g_oMQTTClient;
ArrayList<CRecord> g_oaRecord;
PFont g_oFontLarge, g_oFontSmall;
float g_fSensor0Min = Float.MAX_VALUE, g_fSensor0Max = -Float.MAX_VALUE;
boolean g_bDoNormalize = true;

void setup()
{
  g_oMQTTClient = new MQTTClient( this );
  g_oMQTTClient.connect( MQTT_BROKER_URI, MQTT_CLIENT_ID, true, MQTT_USER, MQTT_PASSWORD );
  g_oMQTTClient.subscribe( MQTT_SUBSCRIPTION_00 );
  
  g_oaRecord = new ArrayList(); // MAX_RECORD_COUNT );
  //for( int i=0; i<MAX_RECORD_COUNT; ++i )
  //  g_oaRecord.add( new CRecord( 0.0f, 0 ) );
  
  size( 800, 600 );
  
  g_oFontLarge = loadFont( TXT_FONT_LARGE );
  g_oFontSmall = loadFont( TXT_FONT_SMALL );
}


void draw()
{
  background( 250 );
  
  if( g_oaRecord.isEmpty() )
    return;
  
  float fX = MARGIN_X; // width - fMarginX;
  float fY = 50.0f;
  
  fill( TXT_FILL );
  textAlign( LEFT );
  textFont( g_oFontLarge );
  text( TXT_TITLE, MARGIN_X, fY );
  fY += TXT_FONT_SIZE_LARGE * 2.0f;
  textFont( g_oFontSmall );
  text( TXT_SENSOR_00 +
    " [�C]",
    //" " + g_oaRecord.get( 0 ).m_fValue + " [°C]",
    MARGIN_X, fY );
  fY += TXT_FONT_SIZE_LARGE * 1.0f;
  
  
  
  textAlign( RIGHT );
  textFont( g_oFontSmall );
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
  text( fTop, width - MARGIN_X - PXL_GAP, fY - PXL_GAP );
  text( fBottom, width - MARGIN_X - PXL_GAP, fY + BAR_HEIGHT - PXL_GAP );
  
  noFill();
  stroke( COLOR_FG );
  strokeWeight( 2.0f );
  strokeJoin( ROUND );
  strokeCap( ROUND );
  final float[] afDash = new float[]{7, 7} ;
  dashline( MARGIN_X, fY, width - MARGIN_X, fY, afDash );
  dashline( MARGIN_X, fY + BAR_HEIGHT, width - MARGIN_X, fY + BAR_HEIGHT, afDash );
  //line( MARGIN_X, fY, width - MARGIN_X, fY );
  //line( MARGIN_X, fY + BAR_HEIGHT, width - MARGIN_X, fY + BAR_HEIGHT );
  
  
  final float fDiff = ( g_fSensor0Max - g_fSensor0Min );
  final float fVNormFac = ( fDiff <= 0.0f ? 1.0f : 1.0f / fDiff );
  final float fBarWidth = ( width - 2 * MARGIN_X ) / ( g_oaRecord.size() );
  
  //fill( 0xAA );
  //noStroke();
  noFill();
  stroke( COLOR_FG );
  strokeWeight( 5.0f );
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
    
    vertex( fX, fY + fV );
    //rect( fX , fY, BAR_WIDTH, oR.m_fValue * BAR_HEIGHT );
    fX += fBarWidth; //BAR_WIDTH;
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
  //println( "message: " + sTopic + " - " + sData );
  
  JSONObject oJSON = parseJSONObject( sData );
  if( oJSON != null )
  {
    final JSONObject oFields = oJSON.getJSONObject( "fields" );;
    final float fValue = oFields.getFloat( MQTT_SENSOR_00_ATTRIB ) * SENSOR_0_VALUE_SCALE;
    if( g_oaRecord.size() >= MAX_RECORD_COUNT )
      g_oaRecord.remove( g_oaRecord.size() - 1 );
      
    final int iTime = 0; // todo
    g_oaRecord.add( 0, new CRecord( fValue, iTime ) );
    
    if( fValue > g_fSensor0Max )
      g_fSensor0Max = fValue;
    if( fValue < g_fSensor0Min )
      g_fSensor0Min = fValue;
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