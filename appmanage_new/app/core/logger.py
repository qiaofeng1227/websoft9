"""
    FileName: logger.py
    Author: Jing.zhao
    Created: 2023-08-30
    Description: This script defines a custom logger that can create and manage two types of logs: 'access' and 'error' for the application.

    Modified by: 
    Modified Date: 
    Modification: 
"""

import os
import logging
from logging.handlers import TimedRotatingFileHandler


class SingletonMeta(type):
    """Singleton Metaclass to ensure only one instance of Logger"""
    _instances = {}

    def __call__(cls, *args, **kwargs):
        """Create an instance if not exist, otherwise return the existing instance"""
        if cls not in cls._instances:
            instance = super().__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]


class Logger(metaclass=SingletonMeta):
    """Custom Logger class for creating and managing two types of loggers: 'access' and 'error'

    Usage:
        from app.core.logger import logger

        # Use the 'access' logger to log info level messages
        logger.access('This is an info message for access logs')

        # Use the 'error' logger to log error level messages
        logger.error('This is an error message for error logs')
    """

    def __init__(self):
        """Initialize method to create 'access' and 'error' loggers"""
        self._access_logger = self._configure_logger("access")
        self._error_logger = self._configure_logger("error")

    def _configure_logger(self, log_type):
        """
        Configure the logger.

        Args:
            log_type (str): Type of the log, either 'access' or 'error'

        Returns:
            logger: Configured logger
        """
        logger = logging.getLogger(log_type)
        logger.setLevel(logging.DEBUG)

        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s')

        log_folder = os.path.join(os.getcwd(), "logs")
        os.makedirs(log_folder, exist_ok=True)

        log_file = os.path.join(log_folder, f"{log_type}_{{asctime}}.log")

        file_handler = TimedRotatingFileHandler(
            filename=log_file,
            when="D",
            interval=1,
            backupCount=30,  # Keep logs for 30 days
            encoding="utf-8"
        )
        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.DEBUG)

        logger.addHandler(file_handler)
        return logger

    @property
    def access(self):
        """Property to access 'access' logger"""
        return self._access_logger.info

    @property
    def error(self):
        """Property to access 'error' logger"""
        return self._error_logger.error


# Create Logger instance
logger = Logger()