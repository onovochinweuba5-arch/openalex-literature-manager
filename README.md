# OpenAlex Literature Manager

A mobile-friendly Flutter app for discovering, screening, saving, and exporting
scholarly literature from the [OpenAlex](https://openalex.org/) catalog.

## Features

- Search OpenAlex works with pagination
- Review abstracts, authors, publication details, and open-access links
- Save papers locally for later screening
- Browse recent search history
- Copy saved or searched papers as CSV

## Run locally

1. Install Flutter with desktop or mobile support enabled.
2. Fetch dependencies:

	```sh
	flutter pub get
	```

3. Run the application:

	```sh
	flutter run
	```

The app uses the public OpenAlex API and does not require an API key.

## Quality checks

```sh
flutter analyze
flutter test
```
