#include <Adafruit_NeoPixel.h>
#include <avr/power.h>

class Button
{
public:
	Button(int pin) : m_pin(pin) {}

	bool Update(uint32_t time)
	{
		if (m_locked)
		{
			if (time < m_unlockTime)
				return false;

			m_locked = false;
		}

		bool state = digitalRead(m_pin) == LOW;

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
	const uint32_t LockDuration = 100;
};

namespace Output
{
	const int Lights = 4;
	const int BuzzerL = 5;
	const int BuzzerR = 6;
}

namespace Input
{
	const int Brightness = 12;
	const int Colour = 11;
	const int Range = 10;
	const int Mode = 9;
	const int BuzzerLevel = 8;
	const int Pause = 3;
	const int Speed = A2;
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

const uint8_t Brightnesses[] = { 20, 80, 140, 255 };

struct BuzzerLevel 
{
	uint32_t duration;
	uint8_t strength;
};

const BuzzerLevel BuzzerLevelsL[] = 
{
	{ 0, 0 },
	{ 70, 140 },
	{ 110, 140 },
	{ 150, 140 },
};

const BuzzerLevel BuzzerLevelsR[] = 
{
	{ 0, 0 },
	{ 50, 140 },
	{ 80, 130 },
	{ 100, 120 },
};

const int Ranges[] = { 0, 5, 10, 15 }; // Pixels to skip at each end.

const int MinPixelDuration = 12;
const int MaxPixelDuration = 50;
const float DefaultSpeed = 0.5f; // [0, 1]

const int PixelCount = 60;
const int ColourCount = sizeof Colours / sizeof Colours[0];
const int BrightnessCount = sizeof Brightnesses / sizeof Brightnesses[0];
const int BuzzerLevelsCount = sizeof BuzzerLevelsL / sizeof BuzzerLevelsL[0];
const int RangesCount = sizeof Ranges / sizeof Ranges[0];

struct _settings
{
	int brightness = 0;
	int colour = 0;
	int range = 0;
	int mode = 0;
	int buzzerLevel = 0;
} 
_settings;

int _currentIndex = -1;
uint32_t _nextPixelTime = 0;
uint32_t _buzzerOffTime = 0;
uint32_t _nextAnalogReadTime = 0;
bool _paused = false;
int _rawPixelDuration = 100;
float _durationFactors[PixelCount / 2];

Adafruit_NeoPixel _pixels = Adafruit_NeoPixel(PixelCount, Output::Lights, NEO_GRB + NEO_KHZ800);

Button _brightnessButton(Input::Brightness);
Button _colourButton(Input::Colour);
Button _rangeButton(Input::Range);
Button _modeButton(Input::Mode);
Button _buzzerLevelButton(Input::BuzzerLevel);
Button _pauseButton(Input::Pause);

void setup() 
{
	Serial.begin(9600);

	_pixels.begin();
	_pixels.setBrightness(0);
	_pixels.show();

	pinMode(Input::BuzzerLevel, INPUT_PULLUP);
	pinMode(Input::Mode, INPUT_PULLUP);
	pinMode(Input::Range, INPUT_PULLUP);
	pinMode(Input::Colour, INPUT_PULLUP);
	pinMode(Input::Brightness, INPUT_PULLUP);
	pinMode(Input::Pause, INPUT_PULLUP);
	
	pinMode(Input::Speed, INPUT);

	pinMode(Output::BuzzerL, OUTPUT);
	pinMode(Output::BuzzerR, OUTPUT);

	digitalWrite(Output::BuzzerL, HIGH);
	digitalWrite(Output::BuzzerR, HIGH);

	updateDurationFactors();
}

int getSkipPixels()
{
	return Ranges[_settings.range];
}

int getRunLength()
{
	return PixelCount - getSkipPixels() * 2 - 1;
}

int getPixel()
{
	const int runLength = getRunLength();
	return getSkipPixels() + runLength - abs(_currentIndex - runLength);
}

int getPixelDuration(int raw)
{
	if (_settings.mode == 0)
		return raw;
	
	const int runLength = getRunLength();
	const int count = (runLength + 1) / 2;
	int index = _currentIndex % runLength;
	if (index >= count)
		index = runLength - index - 1;

	return int(raw * _durationFactors[index]);
}

void updateDurationFactors()
{
	const int count = (getRunLength() + 1) / 2;
	
	float last_t = 0;
	for (int i = 0; i < count; ++i)
	{
		const float x = ((count - i - 1) / float(count));
		const float t = acos(x) * 2 / 3.141; // [0, 1]
		const float dt = t - last_t;

		_durationFactors[i] = dt * count;
		last_t = t;
	}
}

void loop() 
{
	const uint32_t now = millis();
	const int currentPixel = getPixel(); // Before we change _settings.range.
	
	bool reset = false;
	
	if (_brightnessButton.Update(now))
	{
		_settings.brightness = (_settings.brightness + 1) % BrightnessCount;
	}	
	else if (_colourButton.Update(now))
	{
		_settings.colour = (_settings.colour + 1) % ColourCount;
	}	
	else if ((reset = _modeButton.Update(now)))
	{
		_settings.mode = _settings.mode ? 0 : 1;
	}
	else if ((reset = _rangeButton.Update(now)))
	{
		_settings.range = (_settings.range + 1) % RangesCount;
		updateDurationFactors();
	}
	else if ((reset = _buzzerLevelButton.Update(now)))
	{
		_settings.buzzerLevel = (_settings.buzzerLevel + 1) % BuzzerLevelsCount;
	}
	else if ((reset = _pauseButton.Update(now)))
	{
		_paused = !_paused;
	}
	
	if (now >= _buzzerOffTime)
	{
		analogWrite(Output::BuzzerL, 255);
		analogWrite(Output::BuzzerR, 255);
	}

	if (now >= _nextAnalogReadTime)
	{
		const int val = analogRead(Input::Speed);
		float speed; // [0, 1]
		if (val > 1000) // Remote disconnected.
		{
			speed = DefaultSpeed;
			_paused = false;
		}
		else
		{
			speed = constrain(val / float(1023 - val), 0, 1);
		}
		
		_rawPixelDuration = MinPixelDuration + int((1 - speed) * (MaxPixelDuration - MinPixelDuration));

		_nextAnalogReadTime = now + 100;
	}
	
	if (reset || now >= _nextPixelTime)
	{
		const int runLength = getRunLength();
		
		_nextPixelTime = now + getPixelDuration(_rawPixelDuration);
		
		if (_currentIndex < 0)
		{
			_currentIndex = 0;
		}
		else
		{
			_pixels.setPixelColor(currentPixel, _pixels.Color(0,0,0));
			_pixels.setBrightness(Brightnesses[_settings.brightness]);

			if (reset)
				_currentIndex = 0;
			else if (!_paused)
				_currentIndex = reset ? 0 : (_currentIndex + 1) % (runLength * 2);
		}
	
		_pixels.setPixelColor(getPixel(), Colours[_settings.colour]);
		_pixels.show();

		if (_currentIndex == 0 || _currentIndex == runLength)
		{
			if (!_paused || reset)
			{
				const BuzzerLevel& buzzerLevel = (_currentIndex ? BuzzerLevelsR : BuzzerLevelsL)[_settings.buzzerLevel];
				if (buzzerLevel.duration)
				{
					analogWrite(_currentIndex ? Output::BuzzerL : Output::BuzzerR, 255); // In case it's on.
					analogWrite(_currentIndex ? Output::BuzzerR : Output::BuzzerL, 255 - buzzerLevel.strength);
					_buzzerOffTime = now + buzzerLevel.duration;
				}
			}
		}
	}
}
