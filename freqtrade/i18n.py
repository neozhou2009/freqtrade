"""
Internationalization (i18n) module for Freqtrade
Provides multi-language support for the application
"""

import gettext
import locale
import os
from pathlib import Path
from typing import Optional

from freqtrade.constants import USERPATH_TRANSLATIONS


class I18nManager:
    """Manages internationalization for Freqtrade"""

    _instance: Optional["I18nManager"] = None
    _current_locale: str = "en"
    _translations: dict = {}

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if not hasattr(self, "_initialized"):
            self._initialized = True
            self._setup_translations()

    def _setup_translations(self):
        """Setup translation catalogs"""
        self.translations_dir = Path(__file__).parent / "translations"
        if not self.translations_dir.exists():
            self.translations_dir.mkdir(parents=True)

        # Load available translations
        for locale_dir in self.translations_dir.iterdir():
            if locale_dir.is_dir() and (locale_dir / "LC_MESSAGES" / "freqtrade.mo").exists():
                locale_name = locale_dir.name
                try:
                    translation = gettext.translation(
                        "freqtrade",
                        localedir=str(self.translations_dir),
                        languages=[locale_name],
                        fallback=False,
                    )
                    self._translations[locale_name] = translation
                except FileNotFoundError:
                    pass

    def set_locale(self, locale_name: str):
        """Set the current locale"""
        if locale_name in self._translations or locale_name == "en":
            self._current_locale = locale_name
            # Try to set system locale if possible
            try:
                locale.setlocale(locale.LC_ALL, locale_name)
            except locale.Error:
                pass  # Fallback to default

    def get_locale(self) -> str:
        """Get current locale"""
        return self._current_locale

    def get_available_locales(self) -> list[str]:
        """Get list of available locales"""
        return ["en"] + list(self._translations.keys())

    def translate(self, message: str, locale_name: Optional[str] = None) -> str:
        """Translate a message"""
        if locale_name is None:
            locale_name = self._current_locale

        # Create cache key with actual locale used
        cache_key = (message, locale_name)

        # Check cache first
        if hasattr(self, "_translation_cache"):
            if cache_key in self._translation_cache:
                return self._translation_cache[cache_key]
        else:
            self._translation_cache = {}

        # Get translation
        if locale_name == "en" or locale_name not in self._translations:
            result = message
        else:
            try:
                result = self._translations[locale_name].gettext(message)
            except KeyError:
                result = message

        # Cache result (limit cache size)
        if len(self._translation_cache) < 1000:
            self._translation_cache[cache_key] = result

        return result


# Global instance
_i18n_manager = I18nManager()


def _(message: str) -> str:
    """Translation function (shorthand)"""
    return _i18n_manager.translate(message)


def ngettext(singular: str, plural: str, n: int) -> str:
    """Plural translation function"""
    locale_name = _i18n_manager.get_locale()
    if locale_name == "en" or locale_name not in _i18n_manager._translations:
        return singular if n == 1 else plural

    try:
        return _i18n_manager._translations[locale_name].ngettext(singular, plural, n)
    except KeyError:
        return singular if n == 1 else plural


def set_locale(locale_name: str):
    """Set application locale"""
    _i18n_manager.set_locale(locale_name)


def get_locale() -> str:
    """Get current application locale"""
    return _i18n_manager.get_locale()


def get_available_locales() -> list[str]:
    """Get available locales"""
    return _i18n_manager.get_available_locales()


def detect_system_locale() -> str:
    """Detect system locale and return supported locale"""
    try:
        system_locale = locale.getdefaultlocale()[0]
        if system_locale:
            # Map common locale variants
            locale_mapping = {
                "zh_CN": "zh_CN",
                "zh_TW": "zh_CN",  # Fallback to simplified Chinese
                "zh": "zh_CN",
                "en_US": "en",
                "en_GB": "en",
                "en": "en",
            }

            # Check for exact match or partial match
            if system_locale in locale_mapping:
                return locale_mapping[system_locale]

            # Check for language code only (e.g., 'zh' from 'zh_HK')
            lang_code = system_locale.split("_")[0]
            if lang_code in locale_mapping:
                return locale_mapping[lang_code]

    except Exception:
        pass

    return "en"  # Default fallback


# Initialize with system locale
def initialize_i18n():
    """Initialize i18n with system locale"""
    detected_locale = detect_system_locale()
    available_locales = get_available_locales()

    if detected_locale in available_locales:
        set_locale(detected_locale)
    else:
        set_locale("en")
