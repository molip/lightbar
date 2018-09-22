#include <Adafruit_NeoPixel.h>
#include <avr/power.h>

class Button
{
public:
	Button(int pin) : m_pin(pin) {}

	bool Update(uint32_t time)
	{
		bool state = digitalRead(m_pin) == LOW;
		
		if (m_locked)
		{
			if (time < m_unlockTime)
				return false;

			m_locked = false;
		}

		if (state != m_state)
		{
			m_locked = true;
			m_unlockTime = time + LockDuration;
			m_state = state;
			return state;
		}

		return false;
	}

private:
	int m_pin;
	bool m_state = false;	
	bool m_locked = false;
	uint32_t m_unlockTime = 0;
	const uint32_t LockDuration = 100000;
};

namespace Output
{
	const int Lights = 6;
}

namespace Input
{
	const int Colour = 8;
	const int Mode = 9;
	const int Speed = A0;
	const int Brightness = A1;
}

const uint32_t Colours[] = 
{
	Adafruit_NeoPixel::Color(255, 255, 255),	
	Adafruit_NeoPixel::Color(255, 0, 0),	
	Adafruit_NeoPixel::Color(0, 255, 0),	
	Adafruit_NeoPixel::Color(255, 255, 0),	
	Adafruit_NeoPixel::Color(0, 0, 255),	
	Adafruit_NeoPixel::Color(255, 0, 255),	
	Adafruit_NeoPixel::Color(0, 255, 255),	
};

const int PixelCount = 60;
const int ColourCount = sizeof Colours / sizeof Colours[0];
int currentColour = 0;
int currentPixel = -1;
uint32_t nextPixelTime = 0;
uint32_t pixelDuration = 40000;

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(PixelCount, Output::Lights, NEO_GRB + NEO_KHZ800);
Button colourButton(Input::Colour);
Button modeButton(Input::Mode);

void setup() 
{
	pixels.begin();
	pixels.setBrightness(0);
	pixels.show();

	pinMode(Input::Colour, INPUT_PULLUP);
	pinMode(Input::Mode, INPUT_PULLUP);
}

int getPixelIndex()
{
	return (PixelCount - 1) - abs(currentPixel - (PixelCount - 1));
}

void loop() 
{
	uint32_t now = micros();

	if (colourButton.Update(now))
		currentColour = (currentColour + 1) % ColourCount;
	
	if (modeButton.Update(now))
	{
	}

	uint64_t durationVal = analogRead(Input::Speed);
	uint64_t brightnessVal = analogRead(Input::Brightness);

	int brightness = map((brightnessVal * brightnessVal) >> 10, 0, 1023, 3, 255);
	pixelDuration = map(durationVal, 0, 1023, 50000, 5000);
	
	const uint32_t colour = Colours[currentColour];

	if (now > nextPixelTime)
	{
		nextPixelTime = now + pixelDuration;
		
		if (currentPixel < 0)
		{
			currentPixel = 0;
		}
		else
		{
			pixels.setPixelColor(getPixelIndex(), pixels.Color(0,0,0));
			pixels.setBrightness(brightness);
			currentPixel = (currentPixel + 1) % (PixelCount * 2 - 2);
		}
		
	
	
		pixels.setPixelColor(getPixelIndex(), colour);
		pixels.show();
	}
}
