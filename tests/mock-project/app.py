"""Mock application with an intentional bug for pipeline testing."""


def divide_numbers(a, b):
    """Divide two numbers. Bug: no zero division handling."""
    return a / b


def format_greeting(name):
    """Format a greeting message. Bug: no None/empty handling."""
    return f"Hello, {name.strip()}!"
