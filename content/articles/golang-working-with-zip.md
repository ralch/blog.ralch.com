+++
Description = ""
comments = "yes"
date = "2015-09-20T14:58:56+01:00"
share = "yes"
title = "Golang: Working with ZIP archives"
tags = ["go"]
categories = ["programming languages", "tutorial"]
+++

Golang has several packages that work with different type of archives.
In this post I will show you how to use `archive/zip` package to compress and 
uncompress `zip` archives.

[Zip](http://bit.ly/1OeinbI) is one of the most common
file formats. It supports `lossless data compression` of one ore more files and 
directories.

### Extracting

You can read the content of `zip` package by using zip reader. Its `File` property 
exposes all files and directories of particular zip package. If you want to extract 
the package, you should recreate all directories and files:

```
func unzip(archive, target string) error {
	reader, err := zip.OpenReader(archive)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(target, 0755); err != nil {
		return err
	}

	for _, file := range reader.File {
		path := filepath.Join(target, file.Name)
		if file.FileInfo().IsDir() {
			os.MkdirAll(path, file.Mode())
			continue
		}

		fileReader, err := file.Open()
		if err != nil {
			return err
		}
		defer fileReader.Close()

		targetFile, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, file.Mode())
		if err != nil {
			return err
		}
		defer targetFile.Close()

		if _, err := io.Copy(targetFile, fileReader); err != nil {
			return err
		}
	}

	return nil
}
```

### Compressing

This operation is more complicated than `extracing`. You can compress a single file 
or an hierarchy of directories. Handling both cases requires to change the file 
header name depending on its type. If the copied content is directory, the header name
should be changed to `<directory_name>/`. For a regular files, its header name is relative 
path `<directory_name>/<file_name>`.

The following function illustrates the algorithm:

```
func zipit(source, target string) error {
	zipfile, err := os.Create(target)
	if err != nil {
		return err
	}
	defer zipfile.Close()

	archive := zip.NewWriter(zipfile)
	defer archive.Close()

	info, err := os.Stat(source)
	if err != nil {
		return nil
	}

	var baseDir string
	if info.IsDir() {
		baseDir = filepath.Base(source)
	}

	filepath.Walk(source, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		header, err := zip.FileInfoHeader(info)
		if err != nil {
			return err
		}

		if baseDir != "" {
			header.Name = filepath.Join(baseDir, strings.TrimPrefix(path, source))
		}

		if info.IsDir() {
			header.Name += "/"
		} else {
			header.Method = zip.Deflate
		}

		writer, err := archive.CreateHeader(header)
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()
		_, err = io.Copy(writer, file)
		return err
	})

	return err
}
```

### Usage

Lets see both functions in action:

```
zipit("/tmp/documents", "/tmp/backup.zip")
zipit("/tmp/report.txt", "/tmp/report-2015.zip")
unzip("/tmp/report-2015.zip", "/tmp/reports/")
```

You can download the samples from [here](https://gist.github.com/iamralch/424e6784facc0ba907ae).
