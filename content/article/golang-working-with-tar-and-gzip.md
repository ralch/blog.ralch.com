+++
Description = ""
comments = "yes"
date = "2015-09-27T14:58:56+01:00"
share = "yes"
title = "Golang: Working with Gzip and Tar"
tags = ["go"]
categories = ["programming languages", "tutorial"]
+++

### Gzip
[Gzip](https://en.wikipedia.org/wiki/Gzip) is another file compression format 
that was created to replace the `compress` program used in early `unix` system.
It is normally used to compress just single files.  Compressed archives are 
created by packaging collections of files into a single tar archive,
and then compressing that archive with gzip. The final `.tar.gz` or `.tgz` file is a tarball.

#### Compressing a file

Compressing operation is very simple to implement. The package exposes `gzip.Writer` struct
that compress any content provided via its `Write` function. You can specify some metadata
information about the compressed file by setting some properties of `gzip.Header`
struct which is embedded into `gzip.Writer`:

```
// The gzip file stores a header giving metadata about the compressed file.
// That header is exposed as the fields of the Writer and Reader structs.
type Header struct {
	Comment string    // comment
	Extra   []byte    // "extra data"
	ModTime time.Time // modification time
	Name    string    // file name
	OS      byte      // operating system type
}
```

You can compress a file by using the following function:

```
func gzipit(source, target string) error {
	reader, err := os.Open(source)
	if err != nil {
		return err
	}

	filename := filepath.Base(source)
	target = filepath.Join(target, fmt.Sprintf("%s.gz", filename))
	writer, err := os.Create(target)
	if err != nil {
		return err
	}
	defer writer.Close()

	archiver := gzip.NewWriter(writer)
	archiver.Name = filename
	defer archiver.Close()

	_, err = io.Copy(archiver, reader)
	return err
}
```

*Note that `target` argument should be a directory.*

#### Decompressing a file

This operation is simple as its contrapart. But in this case we should use 
`gzip.Reader` to read the compressed array of bytes. We can read the metadata information
such as compressed file name via `gzip.Header` struct (embedded in `gzip.Reader`)

If you need to uncompress a gzip package, you should use this sample:

```
func ungzip(source, target string) error {
	reader, err := os.Open(source)
	if err != nil {
		return err
	}
	defer reader.Close()

	archive, err := gzip.NewReader(reader)
	if err != nil {
		return err
	}
	defer archive.Close()

	target = filepath.Join(target, archive.Name)
	writer, err := os.Create(target)
	if err != nil {
		return err
	}
	defer writer.Close()

	_, err = io.Copy(writer, archive)
	return err
}
```

*Note that `target` argument should be a directory.*

You can download the `gzip` example from [here]().

#### Usage

You can use both functions in the following way:

```
gzipit("/tmp/document.txt", "/tmp")
ungzip("/tmp/document.txt.gz", "/tmp")
```

### Tar
[Tar](http://bit.ly/1DqSuzH) is an archive file for 
distribution of hudge fileset. Known as `tap archive` it was developed to
write data to sequential `io` devices. 

The tar contains multiple paramaeters, such as timestamp, ownership, file 
permissions and directories.

If you want to create a tar package, you should use the following
code snippet walk through the directory hierarchy and write its content. Every
written header encodes metadata file information `os.FileInfo`.
Because os.FileInfo's Name method returns only the base name of
the file it describes, it may be necessary to modify the Name field
of the returned header to provide the full path name of the file.

```
func tarit(source, target string) error {
	filename := filepath.Base(source)
	target = filepath.Join(target, fmt.Sprintf("%s.tar", filename))
	tarfile, err := os.Create(target)
	if err != nil {
		return err
	}
	defer tarfile.Close()

	tarball := tar.NewWriter(tarfile)
	defer tarball.Close()

	info, err := os.Stat(source)
	if err != nil {
		return nil
	}

	var baseDir string
	if info.IsDir() {
		baseDir = filepath.Base(source)
	}

	return filepath.Walk(source, 
	func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		header, err := tar.FileInfoHeader(info, info.Name())
		if err != nil {
			return err
		}

		if baseDir != "" {
			header.Name = filepath.Join(baseDir, strings.TrimPrefix(path, source))
		}

		if err := tarball.WriteHeader(header); err != nil {
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
		_, err = io.Copy(tarball, file)
		return err
	})
}
```

To unpack a tar you should use `tar.Reader` struct to read all headers. Every
header declares the begining of every directory and file in the tarball. By accessing
its `FileInfo` property you can recreate the files and the directories:

```
func untar(tarball, target string) error {
	reader, err := os.Open(tarball)
	if err != nil {
		return err
	}
	defer reader.Close()
	tarReader := tar.NewReader(reader)

	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		path := filepath.Join(target, header.Name)
		info := header.FileInfo()
		if info.IsDir() {
			if err = os.MkdirAll(path, info.Mode()); err != nil {
				return err
			}
			continue
		}

		file, err:= os.OpenFile(path, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, info.Mode())
		if err != nil {
			return err
		}
		defer file.Close()
		_, err =io.Copy(file, tarReader)
		if err != nil {
			return err
		}
	}
```

*Note that `target` argument should be a directoy.*

You can download the `tar` code snippets from [here](https://gist.github.com/svett/76799ba2edca89961be6).

#### Usage

You can use call the functions in the following way:

```
tarit("/tmp/utils", "/tmp")
untar("/tmp/utils.tar", "/tmp")
```
