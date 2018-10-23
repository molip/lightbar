#include <Adafruit_NeoPixel.h>
#include <EEPROM.h>

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
	const int Pause2 = 7;
	const int Pause = 3;
	const int Speed = A2;
}

const uint32_t Colours[] = 
{
	Adafruit_NeoPixel::Color(255, 255, 255), 	// White	
	Adafruit_NeoPixel::Color(255, 50, 0),		// Red
	Adafruit_NeoPixel::Color(255, 0, 140),		// Pink
	Adafruit_NeoPixel::Color(140, 0, 255),		// Purple
	Adafruit_NeoPixel::Color(0, 0, 255),		// Blue
	Adafruit_NeoPixel::Color(0, 130, 255),		// L blue
	Adafruit_NeoPixel::Color(0, 255, 0),		// Green
	Adafruit_NeoPixel::Color(233, 255, 0),		// Yellow
	Adafruit_NeoPixel::Color(255, 128, 0),		// Orange
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
const uint32_t SettingsWriteDelay = 3000;
const int PixelCount = 58;
const int ColourCount = sizeof Colours / sizeof Colours[0];
const int BrightnessCount = sizeof Brightnesses / sizeof Brightnesses[0];
const int BuzzerLevelsCount = sizeof BuzzerLevelsL / sizeof BuzzerLevelsL[0];
const int RangesCount = sizeof Ranges / sizeof Ranges[0];
const int ModesCount = 3;

enum class Settings { Brightness, Colour, Range, Mode, BuzzerLevel, _Count };
const uint8_t SettingStateCount[] = { BrightnessCount, ColourCount, RangesCount, ModesCount, BuzzerLevelsCount };
uint8_t _settings[(int)Settings::_Count];

int _currentIndex = -1;
uint32_t _nextPixelTime = 0;
uint32_t _buzzerOffTime = 0;
uint32_t _nextAnalogReadTime = 0;
uint32_t _nextSettingsWriteTime = 0;
bool _paused = true;
int _rawPixelDuration = 100;
float _durationFactors[PixelCount / 2];

Adafruit_NeoPixel _pixels = Adafruit_NeoPixel(PixelCount, Output::Lights, NEO_GRB + NEO_KHZ800);

Button _brightnessButton(Input::Brightness);
Button _colourButton(Input::Colour);
Button _rangeButton(Input::Range);
Button _modeButton(Input::Mode);
Button _buzzerLevelButton(Input::BuzzerLevel);
Button _pauseButton(Input::Pause);
Button _pauseButton2(Input::Pause2);

uint8_t getSetting(Settings type)
{
	return _settings[(int)type];
}

void advanceSetting(Settings type)
{
	const int index = (int)type;
	_settings[index] = (_settings[index] + 1) % SettingStateCount[index];
}

void saveSettings()
{
	Serial.println("Saving settings...");
	for (int i = 0; i < (int)Settings::_Count; ++i)
	{
		EEPROM.update(i, _settings[i]);
		Serial.println(_settings[i]);
	}
}

void loadSettings()
{
	Serial.println("Loading settings...");
	for (int i = 0; i < (int)Settings::_Count; ++i)
	{
		_settings[i] = EEPROM.read(i);
		Serial.println(_settings[i]);
	}
}

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
	pinMode(Input::Pause2, INPUT_PULLUP);
	
	pinMode(Input::Speed, INPUT);

	pinMode(Output::BuzzerL, OUTPUT);
	pinMode(Output::BuzzerR, OUTPUT);

	digitalWrite(Output::BuzzerL, HIGH);
	digitalWrite(Output::BuzzerR, HIGH);

	//saveSettings();
	loadSettings();

	updateDurationFactors();
}

int getSkipPixels()
{
	return Ranges[getSetting(Settings::Range)];
}

int getRunLength()
{
	return PixelCount - getSkipPixels() * 2 - 1;
}

int getPixel()
{
	const int runLength = getRunLength();

	if (getSetting(Settings::Mode) == 2)
		return getSkipPixels() + (_currentIndex >= runLength ? runLength : 0);
		
	return getSkipPixels() + runLength - abs(_currentIndex - runLength);
}

int getPixelDuration(int raw)
{
	if (getSetting(Settings::Mode) != 1)
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
	const int currentPixel = getPixel(); // Before we change Settings::Range.
	
	bool reset = false;
	bool changed = false;
	
	if (_brightnessButton.Update(now))
	{
		advanceSetting(Settings::Brightness);
		changed = true;
	}	
	else if (_colourButton.Update(now))
	{
		advanceSetting(Settings::Colour);
		changed = true;
	}	
	else if (_modeButton.Update(now))
	{
		advanceSetting(Settings::Mode);
		reset = changed = true;
	}
	else if (_rangeButton.Update(now))
	{
		advanceSetting(Settings::Range);
		updateDurationFactors();
		reset = changed = true;
	}
	else if (_buzzerLevelButton.Update(now))
	{
		advanceSetting(Settings::BuzzerLevel);
		reset = changed = true;
	}
	else if (_pauseButton.Update(now) || _pauseButton2.Update(now))
	{
		_paused = !_paused;
		reset = true;
	}
	
	if (changed)
	{
		_nextSettingsWriteTime = now + SettingsWriteDelay;
	}
	else if (_nextSettingsWriteTime && now >= _nextSettingsWriteTime)
	{
		saveSettings();
		_nextSettingsWriteTime = 0;
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
			_pixels.setBrightness(Brightnesses[getSetting(Settings::Brightness)]);

			if (reset)
				_currentIndex = 0;
			else if (!_paused)
				_currentIndex = reset ? 0 : (_currentIndex + 1) % (runLength * 2);
		}
	
		_pixels.setPixelColor(getPixel(), Colours[getSetting(Settings::Colour)]);
		_pixels.show();

		if (_currentIndex == 0 || _currentIndex == runLength)
		{
			if (!_paused || reset)
			{
				const BuzzerLevel& buzzerLevel = (_currentIndex ? BuzzerLevelsR : BuzzerLevelsL)[getSetting(Settings::BuzzerLevel)];
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
