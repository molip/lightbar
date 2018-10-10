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

struct _settings
{
	int currentColour = 0;
	uint32_t pixelDuration = 40000;
} 
_settings;

int _currentIndex = -1;
uint32_t _nextPixelTime = 0;

Adafruit_NeoPixel _pixels = Adafruit_NeoPixel(PixelCount, Output::Lights, NEO_GRB + NEO_KHZ800);
Button _colourButton(Input::Colour);
Button _modeButton(Input::Mode);

void setup() 
{
	_pixels.begin();
	_pixels.setBrightness(0);
	_pixels.show();

	pinMode(Input::Colour, INPUT_PULLUP);
	pinMode(Input::Mode, INPUT_PULLUP);
}

int getPixel()
{
	return (PixelCount - 1) - abs(_currentIndex - (PixelCount - 1));
}

void loop() 
{
	uint32_t now = micros();

	if (__modeButton.Update(now))
		_settings.currentColour = (_settings.currentColour + 1) % ColourCount;
	
	if (_modeButton.Update(now))
	{
	}

	uint64_t durationVal = analogRead(Input::Speed);
	uint64_t brightnessVal = analogRead(Input::Brightness);

	int brightness = map((brightnessVal * brightnessVal) >> 10, 0, 1023, 3, 255);
	_settings.pixelDuration = map(durationVal, 0, 1023, 50000, 5000);
	
	const uint32_t colour = Colours[_settings.currentColour];

	if (now > _nextPixelTime)
	{
		_nextPixelTime = now + _settings.pixelDuration;
		
		if (_currentIndex < 0)
		{
			_currentIndex = 0;
		}
		else
		{
			_pixels.setPixelColor(getPixel(), _pixels.Color(0,0,0));
			_pixels.setBrightness(brightness);
			_currentIndex = (_currentIndex + 1) % (PixelCount * 2 - 2);
		}
		
	
		_pixels.setPixelColor(getPixelIndex(), colour);
		_pixels.show();
	
	}
}
