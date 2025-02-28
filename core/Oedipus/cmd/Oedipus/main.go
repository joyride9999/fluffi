/*
Copyright 2017-2019 Siemens AG

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Author(s): Roman Bendt, Thomas Riedmaier
*/

package main

import (
	"Oedipus/errs"
	"bytes"
	"database/sql"
	"encoding/hex"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"math"
	"math/rand"
	"os"
	"path"
	"strconv"
	"strings"
	"time"

	"github.com/sergi/go-diff/diffmatchpatch"

	_ "github.com/go-sql-driver/mysql"
)

const (
	LEFT uint8 = 1 << iota
	RIGHT
	INSERT
	DELETE
)

type Mutation struct {
	ID     uint64
	Rating int64

	CreatorGUID string
	CreatorLID  uint64

	ParentGUID string
	ParentLID  uint64
	Parent     *Mutation
	Children   []*Mutation
}

func (m *Mutation) Pretty() string {
	return fmt.Sprintf("%d (%d): %s-%d (%s-%d)", m.ID, m.Rating, m.CreatorGUID, m.CreatorLID, m.ParentGUID, m.ParentLID)
}
func (m *Mutation) NumChildren() int {
	var sum = 0
	for c := range m.Children {
		sum += m.Children[c].NumChildren()
	}
	return len(m.Children) + sum
}

func main() {

	fNum := flag.Int("n", 1, "how many mutations to produce")
	fPrefix := flag.String("o", "oede_", "output folder and file name prefix")
	fDbstring := flag.String("d", "", "connect string for fuzzjob database")
	fVerbose := flag.Bool("v", false, "print pretty diffs to stdout")
	fLeft:= flag.Bool("l", false, "merge strategy left")
	fRight := flag.Bool("r", false, "merge strategy right")
	fInsert := flag.Bool("i", false, "merge strategy insert")
	fDelete := flag.Bool("m", false, "merge strategy delete")

	flag.Usage = func() {
		log.Println("Οἰδίπους - a dual parent testcase mutator")
		log.Println("    gimme more than one file, then I merge those.")
		log.Println("    gimme db credentials and one file, then I will find my own mother.")
		log.Println("    the best strategy currently seems to be \"-r -m\"")
		log.Println("USAGE: Οἰδίπους [OPTS] FILENAME1 [FILENAMEn]")
		log.Println("OPTS:")
		flag.PrintDefaults()
		log.Println("FILENAMEx:")
		log.Println("	name of the input file[s] to merge")
	}

	flag.Parse()
	filenames := flag.Args()
	numMutations := *fNum
	files := make([][]byte, 1+numMutations)
	var strategy uint8
	if *fLeft {
		strategy = strategy | LEFT
	}
	if *fRight {
		strategy = strategy | RIGHT
	}
	if *fInsert{
		strategy = strategy | INSERT
	}
	if *fDelete{
		strategy = strategy | DELETE
	}

	errs.FlogOpen()
	defer errs.FlogClose()
	foe, f := errs.Foe("Oedipus:")

	rand.Seed(time.Now().UnixNano())

	if len(filenames) == 1 {
		// first, read file as first parent
		fp1, e := os.Open(filenames[0])
		foe(e, "could not open file 1")
		files[0], e = ioutil.ReadAll(fp1)
		foe(e, "could not read file 1")
		_ = fp1.Close()

		// second, decode database credential string and connect to mysql
		// "fluffi_gm:fluffi_gm@tcp(db.fluffi:3306)/fluffi_miniweb"
		// 666c756666695f676d3a666c756666695f676d40746370286865787861676f6e2e666c756666693a33333036292f666c756666695f6d696e69776562
		bstr, e := hex.DecodeString(*fDbstring)
		foe(e, "cannot decode db connection hex string")
		db, e := sql.Open("mysql", string(bstr))
		foe(e, "error opening sql connection")

		// build cases of all mutations
		// meanwhile, keep track of all initial testcases
		var cases []Mutation
		var initials []*Mutation
		r, e := db.Query("SELECT ID,CreatorServiceDescriptorGUID,CreatorLocalID,ParentServiceDescriptorGUID,ParentLocalID,Rating FROM interesting_testcases")
		foe(e, "error executing query 2")
		defer r.Close()
		for r.Next() {
			var m Mutation
			e = r.Scan(&m.ID, &m.CreatorGUID, &m.CreatorLID, &m.ParentGUID, &m.ParentLID, &m.Rating)
			foe(e, "error scanning rows returned from query")
			cases = append(cases, m)
		}
		r.Close()

		// find root parent of given testcase
		// ./testcaseFiles/88e83b91-997d-464f-810f-8940e0a0995f/queueFillerTempDir/b58f8aa6-be79-4ccb-972e-789f0e163909-9726
		parts := strings.Split(path.Base(filenames[0]), "-")
		lID, e := strconv.Atoi(parts[len(parts)-1])
		gID := strings.TrimSuffix(path.Base(filenames[0]), "-"+parts[len(parts)-1])
		var first *Mutation

		// stupidly build some trees (n²)
		for i, node := range cases {
			if node.CreatorGUID == "initial" {
				initials = append(initials, &cases[i])
				continue
			}
			if node.CreatorLID == uint64(lID) && node.CreatorGUID == gID {
				first = &cases[i]
			}
			// find parent
			for j, maybe := range cases {
				// log.Printf("%d : %d (%d)\n", i, j, len(cases))
				if maybe.CreatorLID == node.ParentLID && maybe.CreatorGUID == node.ParentGUID {
					cases[j].Children = append(cases[j].Children, &cases[i])
					cases[i].Parent = &cases[j]
					break
				}
			}
			// if i % 5000 == 0 { log.Println("reached:", i) }
		}

		// get parent of first and remove it from initials list (if there are more than one initial testcases
		// TODO this breaks if we get a wrong named file (aka has no parent) (??? after fix???)
		if first != nil {
			var firstsParent *Mutation
			firstsParent = first
			for firstsParent.Parent != nil {
				firstsParent = firstsParent.Parent
			}
			for i := range initials {
				if initials[i] == firstsParent {
					log.Println("file was child of", "(", initials[i].CreatorGUID, "-", initials[i].CreatorLID, ")")
					if len(initials) > 1 {
						initials = append(initials[:i], initials[i+1:]...)
					}
					break
				}
			}
		}
		// print info on trees
		for n, node := range initials {
			log.Println(node.Pretty(), "children: ", cases[n].NumChildren())
		}
		// for as many as needed walk over the initial list and go down a tree
		for i := 0; i < numMutations; i++ {
			var target, last *Mutation
			if i < len(initials) {
				// first, we apply the mutation to all the initial testcases.
				target = initials[i]
			} else {
				// after that, we descent down the trees of those initials and use their latest children
				target = initials[i%len(initials)]
				for len(target.Children) != 0 {
					last = target
					if len(target.Children) == 1 {
						target = target.Children[0]
					} else {
						target = target.Children[ rand.Intn(len(target.Children)) ]
					}
				}
				// remove the target from possible reruns into this tree
				if target == initials[i%len(initials)] {
					// if target is still the initial one, it does not have children.
					initials = append(initials[:i%len(initials)], initials[1+(i%len(initials)):]...)
				} else { // this whole thing should only trigger on initials that do not have children
					last.Children = last.Children[1:]
				}
			}
			// load target bytes to file structure
			log.Println("selected:", target.Pretty())
			r, e = db.Query("SELECT RawBytes FROM interesting_testcases WHERE CreatorServiceDescriptorGUID = ? AND CreatorLocalID = ?", target.CreatorGUID, target.CreatorLID)
			foe(e, "error executing query 1")
			defer r.Close()
			done := false
			for r.Next() {
				if !done {
					done = true
					e = r.Scan(&files[1+i])
					foe(e, "error scanning rows returned from query")
				} else {
					f("more than one row was returned for our very specialized query. db may be inconsistent.")
				}
			}
			r.Close()
		}
		db.Close()

	} else if len(filenames) > 1 {
		f("please do not use this codepath yet. this is more than unimplemented, but less than functional :)")
		// TODO this is not entirely consistent. if we supplied less than the requested number of mutations, we do not have enough []bytes in files[].
		// FIXME in that case the mutation engine below will fail.
		for i := 0; i < int(math.Min(float64(len(filenames)), float64(1+*fNum))); i++ {
			fp, e := os.Open(filenames[i])
			foe(e, "could not open file "+string(i))
			files[i], e = ioutil.ReadAll(fp)
			foe(e, "could not read file "+string(i))
			_ = fp.Close()
		}
	} else {
		flag.Usage()
		f("no initial file given")
	}

	for i := 1; i <= numMutations; i++ {
		fp, e := os.OpenFile((*fPrefix)+strconv.Itoa(i), os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
		foe(e, "could not open target mutation file for writing")
		_, e = fp.Write(mergeInputs(files[0], files[i], *fVerbose, strategy))
		foe(e, "could not write to target mutation file")
		_ = fp.Close()
	}
}

func mergeInputs(a1, a2 []byte, verbose bool, strat uint8 ) []byte {
	foe, f := errs.Foe("mergeInputs:")
	d := diffmatchpatch.New()

	b1 := hex.EncodeToString(a1)
	b2 := hex.EncodeToString(a2)

	var diffs []diffmatchpatch.Diff
	if strat&LEFT != 0 {
		diffs = d.DiffMain(b1, b2, false)
	} else if strat&RIGHT != 0 {
		diffs = d.DiffMain(b2, b1, false)
	} else {
		if rand.Intn(1) == 1 {
			diffs = d.DiffMain(b1, b2, false)
		} else {
			diffs = d.DiffMain(b2, b1, false)
		}
	}

	if verbose {
		log.Println(d.DiffPrettyText(diffs))
	}

	var b bytes.Buffer
	var e error
	for _, d := range diffs {
		switch d.Type {
		case diffmatchpatch.DiffInsert:
			if strat&INSERT != 0 {
				_, e = b.WriteString(d.Text)
			}
		case diffmatchpatch.DiffDelete:
			if strat&DELETE != 0 {
				_, e = b.WriteString(d.Text)
			}
		case diffmatchpatch.DiffEqual:
			_, e = b.WriteString(d.Text)
		default:
			f("wrong difftype found")
		}
		foe(e, "error writing to buffer:")
	}

	ret, e := hex.DecodeString(b.String())
	return ret
}
