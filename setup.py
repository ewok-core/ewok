from setuptools import setup

with open("requirements.txt") as reqs_file:
    requirements = reqs_file.read().split("\n")

setup(
    name="ewok",
    packages=["ewok", "ewok.compile"],
    install_requires=requirements,
    python_requires=">=3.10",
)
