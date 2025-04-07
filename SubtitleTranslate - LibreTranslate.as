/*
	real time subtitle translate for PotPlayer using LibreTranslate API
	https://libretranslate.com/docs/
*/

// void OnInitialize()
// void OnFinalize()
// string GetTitle() 														-> get title for UI
// string GetVersion														-> get version for manage
// string GetDesc()															-> get detail information
// string GetLoginTitle()													-> get title for login dialog
// string GetLoginDesc()													-> get desc for login dialog
// string GetUserText()														-> get user text for login dialog
// string GetPasswordText()													-> get password text for login dialog
// string ServerLogin(string User, string Pass)								-> login
// string ServerLogout()													-> logout
//------------------------------------------------------------------------------------------------
// array<string> GetSrcLangs() 												-> get source language
// array<string> GetDstLangs() 												-> get target language
// string Translate(string Text, string &in SrcLang, string &in DstLang) 	-> do translate !!

string server_address = "https://libretranslate.com";
string server_port = "443";
string api_key = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
string UserAgent = "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari";

// Plugin Initialization
void OnInitialize()
{
	// HostOpenConsole();
	HostPrintUTF8("LibreTranslate translation plugin loaded.");
}

// Plugin Finalization
void OnFinalize()
{
	HostPrintUTF8("LibreTranslate translation plugin unloaded.");
}

array<string> LangTable =
{
	"ar",
	"az",
	"bg",
	"bn",
	"ca",
	"cs",
	"da",
	"de",
	"el",
	"en",
	"eo",
	"es",
	"et",
	"eu",
	"fa",
	"fi",
	"fr",
	"ga",
	"gl",
	"he",
	"hi",
	"hu",
	"id",
	"it",
	"ja",
	"ko",
	"lt",
	"lv",
	"ms",
	"nb",
	"nl",
	"pb",
	"pl",
	"pt",
	"ro",
	"ru",
	"sk",
	"sl",
	"sq",
	"sv",
	"th",
	"tl",
	"tr",
	"uk",
	"ur",
	"zh",
	"zt"
};

array<string> GetSrcLangs()
{
	array<string> ret = LangTable;
	ret.insertAt(0, "auto"); // auto
	return ret;
}

array<string> GetDstLangs()
{
	array<string> ret = LangTable;

	return ret;
}

string GetTitle()
{
	return "{$CP949=LibreTranslate$}{$CP950=LibreTranslate$}{$CP0=LibreTranslate$}";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "<a href=\"https://github.com/LibreTranslate/LibreTranslate\">https://github.com/LibreTranslate/LibreTranslate/</a>";
}

string GetLoginTitle()
{
	return "{$CP949=입력 LibreTranslate 서버 정보$}{$CP950=輸入 LibreTranslate 伺服器資訊$}{$CP0=Input LibreTranslate server information$}";
}

string GetLoginDesc()
{
	return "{$CP949=입력 LibreTranslate 서버 정보$}{$CP950=輸入 LibreTranslate 伺服器資訊$}{$CP0=Input LibreTranslate server information$}";
}

string GetUserText()
{
	return "{$CP949=서버 주소:$}{$CP950=伺服器位址:$}{$CP0=Server address:$}";
}

string GetPasswordText()
{
	return "{$CP949=API 키:$}{$CP950=API 金鑰:$}{$CP0=API Key:$}";
}

string ServerLogin(string User, string Pass)
{
	User = User.Trim();
	Pass = Pass.Trim();

	int sepPos = User.find(":");
	string address = sepPos != -1 ? User.substr(0, sepPos).Trim() : User;
	string port = sepPos != -1 ? User.substr(sepPos + 1).Trim() : "";

	if (address.empty())
	{
		HostPrintUTF8("Address not entered. use default address.");
		address = "https://libretranslate.com"; // 默认地址
	}

	server_port = !port.empty() ? port : (address.find("https") != -1 ? "443" : "80");

	server_address = address;
	// server_address = User;
	api_key = Pass;

	HostPrintUTF8("API Key and server address (plus server port) successfully configured.");
	return "200 ok";
}

void ServerLogout()
{
	api_key = "";
	server_address = "https://libretranslate.com";
	server_port = "443";
	HostPrintUTF8("{$CP0=Successfully logged out.$}\n");
}

string Translate(string Text, string &in SrcLang, string &in DstLang)
{
	string ret = "";
	HostPrintUTF8(Text);
	if (!Text.empty())
	{
		string enc = HostUrlEncode(Text);

		// Request data
		if (SrcLang.empty())
			SrcLang = "auto";
		string api = "";
		if (!api_key.empty())
			api = "&api_key=" + api_key;
		string requestData = "source=" + SrcLang + "&target=" + DstLang + "&q=" + enc + "&alternatives=0" + "&format=text" + api;
		HostPrintUTF8(requestData);

		string url = server_address + ":" + server_port + "/translate";
		// string url = server_address +  "/translate";
		HostPrintUTF8(url);

		string headers = "accept: application/json\nContent-Type: application/x-www-form-urlencoded";

		string response = HostUrlGetString(url, UserAgent, headers, requestData);
		if (response.empty())
		{
			HostPrintUTF8("Translation request failed. Please check network connection or API Key.");
			return "Translation request failed";
		}

		JsonReader Reader;
		JsonValue Root;
		if (!Reader.parse(response, Root))
		{
			HostPrintUTF8("Failed to parse API response.");
			return "Translation failed";
		}
		if (Root.isObject())
		{
			SrcLang = "UTF8";
			DstLang = "UTF8";

			array<string> keys = Root.getKeys();
			bool result = false;
			for (uint i = 0; i < keys.size(); i++)
			{
				if ("error" == keys[i])
				{
					result = true;
					break;
				}
			}
			if (result)
			{
				if (Root["error"].isString())
				{
					JsonValue error = Root["error"];
					ret = "error: " + error.asString();
				}
			}
			else
			{
				if (Root["translatedText"].isString())
				{

					string translatedText = Root["translatedText"].asString();
					if (DstLang == "fa" || DstLang == "ar" || DstLang == "he")
					{
						translatedText = "\u202B" + translatedText;
					}
					ret = translatedText;
				}
			}
		}
	}
	HostPrintUTF8(ret);
	return ret;
}
