"""
Configuration support for internationalization
"""

from typing import Optional

from freqtrade.i18n import detect_system_locale, get_available_locales, set_locale


def setup_i18n_from_config(config: dict) -> None:
    """
    Setup internationalization based on configuration

    Args:
        config: Freqtrade configuration dictionary
    """
    # Get language setting from config or detect system locale
    language = config.get("language")

    if language is None:
        language = detect_system_locale()

    # Check if requested language is available
    available_locales = get_available_locales()

    if language not in available_locales:
        # Fallback to English if requested language is not available
        language = "en"

    # Set the locale
    set_locale(language)


def get_language_from_config(config: dict) -> str:
    """
    Get language setting from config or return default

    Args:
        config: Freqtrade configuration dictionary

    Returns:
        Language code (e.g., 'en', 'zh_CN')
    """
    return config.get("language", detect_system_locale())
