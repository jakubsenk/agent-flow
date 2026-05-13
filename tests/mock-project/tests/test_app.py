"""Tests for mock application — verify bug fixes."""

import pytest
from app import divide_numbers, format_greeting


def test_divide_numbers_normal():
    assert divide_numbers(10, 2) == 5.0


def test_divide_numbers_zero():
    """This test fails with the buggy code — fixer should add zero handling."""
    with pytest.raises(ValueError, match="Cannot divide by zero"):
        divide_numbers(10, 0)


def test_format_greeting_normal():
    assert format_greeting("World") == "Hello, World!"


def test_format_greeting_empty():
    """This test fails with the buggy code — fixer should add empty handling."""
    with pytest.raises(ValueError, match="Name cannot be empty"):
        format_greeting("")
