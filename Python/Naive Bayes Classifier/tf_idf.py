import re
import os, os.path
import timeit
import math
from collections import Counter,defaultdict

def hasNumbers(string):
    return any(char.isdigit() for char in string)

'''
#reading the lexicon from text file
file = open("AFINN.txt") #Using AFINN
#reading the lexicon as a text file
with file as f:
     lexicon = {} #creating new dictionary
     for line in f: #loop through the file
         line = line.split() #take away the white space
         if line: lexicon[line[0]] = line[1] #add to dictionary
'''

file = open('AFINN.txt')
with file as f:
     lexicon = {}
     for line in f:
         line = line.split()
         if line and hasNumbers(line[1]):
            lexicon[line[0]] = line[1]
         elif line and hasNumbers(line[2]):
            temp = [line[0],line[1]]
            temp_string = ' '.join(temp)
            lexicon[temp_string] = line[2]
         elif line and hasNumbers(line[3]):
            temp = [line[0],line[1],line[2]]
            lexicon[' '.join(temp)] = line[3]


def negReviews():
   negDir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/test/neg'
   #posDir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/test/pos'
   return negDir

def posReviews():
    posDir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/test/pos'
    return posDir

def getReviews(data_set):
    #data_set = input("Which dataset do you want to perform calculations on?")
    neg_dir = ''
    pos_dir = ''
    if data_set == 'test' or data_set == 'Test':
       neg_dir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/test/neg'
       pos_dir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/test/pos'
    elif data_set == 'train' or data_set == 'Train':
       neg_dir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/train/neg'
       pos_dir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/train/pos'
       #neutral_dir = '/home/dgarcia4/csc365/hw01/aclImdb_v1/aclImdb/train/unsup'
    return neg_dir,pos_dir

#print(getReviews())  

"""
def readFile(fileName):
#tokenizes the text file, return a list od tokens
    with open(fileName) as f: #opening the text file
         s = " ".join([x.strip() for x in f]) #getting rid of \n and \t in text
         token = re.findall(r"[\w']+", s.lower()) #getting rid of punctuation and making the text lowercase(so we can compare with dictionary)
    return token
"""

def readFile2(dir,fileName):
#opens a text file in some directory
    with open(os.path.join(dir,fileName)) as f: #opening the text file
         s = " ".join([x.strip() for x in f]) #getting rid of \n and \t in text
         token = re.findall(r"[\w']+", s.lower()) #getting rid of punctuation 
    return token

def featureVector(dir,fileName):
#creates a feature vector, return a dictionary of words with their counts
    counter = Counter()
    token = readFile2(dir,fileName)
    for word in token: #going through every word in tokenized string
        if lexicon.get(word): #if the word is in the lexicon
           counter[word] += 1 #add word as key, increment 1
    return counter


def totalWords(dir,fileName):
#calculates the total amount of words in a document
    token = readFile2(dir,fileName)
    wordCount = len(token)
    return wordCount
   
"""
def termFrequency(dir,fileName):
#calculates the term frequency in a document, returns a float 
    wordCounter = featureVector(dir,fileName)
    totalWordCount = totalWords(dir,fileName)
    wordFrequency = {}
    for word,count in wordCounter.items():
        tf = count/totalWordCount
        wordFrequency[word] = tf
        #print('Term Frequency for ',word,': ',count,'/',totalWordCount,'=',tf)
    return wordFrequency
"""

def getDoc(dir):
#get names of files in a directory, returns list of file names
    docList = [name for name in os.listdir(dir) if os.path.isfile(os.path.join(dir, name))]
    return docList

def toBeNamedLater(reviews_dir):
#create a list of both negative and positive reviews
#return a dict of list of negative reviews and list of positive reviews
#key - directory
#value - reviews in directory
   newDict = {}
   newDict[reviews_dir[0]] = getDoc(reviews_dir[0])
   #newDict[reviews_dir[1]] = getDoc(reviews_dir[1])
   return newDict

#print(toBeNamedLater())

def getAllWordCounts(docs):
#get the word counts for every document
#returns dict of counters
#key: file name of review
#value: feature vector associated with review
    #for dir,file_list in docs.items():
    doc_counters = {file_name: featureVector(dir,file_name) for dir,file_list in docs.items() for file_name in file_list}
    return doc_counters

#print(getAllWordCounts())

def getAllTotalWords(docs):
#get total words counts for every document
#returns dict of total word counts
#key: file name of review
#value: how many words are in that review
    doc_counters = {file_name: totalWords(dir,file_name) for dir,file_list in docs.items() for file_name in file_list}
    return doc_counters

#print(getAllTotalWords())

def getTF(wordCounts,totalWords):
#calculates the term frequency for every word in both negative and positive reviews
#returns a dictionary
#key: file name, value: dict of word:tf values
   #docs = toBeNamedLater()
   #wordCounts = getAllWordCounts() #get counts
   #totalWords = getAllTotalWords() #get totalwords
   tf_values = {}

   #for reviews,wordCount in zip(wordCounts,totalWords):
   tf_values = {file_name: {word: count/word_count for word,count in reviews.items()} for (file_name,reviews), word_count in zip(wordCounts.items(),totalWords.values())}
   """
   for reviews,wordCount in zip(wordCounts,totalWords): 
       for word,count in reviews.items():
           tf = count/wordCount
           tf_values[word] = tf
   """
   return tf_values

#print(getTF())
#print(getAllTotalWords())


def makeVocab(tf):
#creates a vocabulary for every word in the lexicon that appears in the documents
#returns a dict of lexicon words associated with a review
    #tf_words = getTF()
    vocab = {file_name: {word for word in tf_values} for file_name,tf_values in tf.items()}
    #vocab = set(vocab)
    return vocab


def getDenom(wordCounts,vocab):
#calculates the amount of documents with a term, for every term in the vocabulary
#returns a dictionary
#key - word
#value - amount of documents with word
    #wordCounts = getAllWordCounts()
    #vocab = makeVocab()
    oh_no = Counter()
    a = {}
    for set, (file_name,reviews) in zip(vocab.values(),wordCounts.items()):
        for words in set:
            if reviews.get(words):
               oh_no[words] += 1
               #a[file_name1] = oh_no       
    return dict(oh_no)

#print(getDenom())
def getIDF(num1,denom):
    #tf_words = getTF()
    #wordCounts = getAllWordCounts()
    num = len(num1)
    #denom = getDenom()
    idf_dict = {}
    """
    for word,freq in denom:
        idf = math.log(num/freq)
        idf_dict[word] = idf
    """
    idf_dict = {word: math.log(num/freq) for word,freq in denom.items()}
    return idf_dict

#print(len(getTF()),len(getIDF()))

def tfIdf(tf,idf_values):
#multiply all the values in tf dictionary with values in idf dictionary
#returns a dict of words mapped with their tf-idf values
    #tf_values = getTF()
    #idf_values = getIDF()

    h = {file_name: {words1: tf*idf for (words1, tf), (idf) in zip(tf_values.items(), idf_values.values())} for file_name,tf_values in tf.items()}

    """
    for (words1, tf), (words2, idf) in zip(tf_values.items(), tdf_values.items()):
        a = tf * idf
        h[words1] = a 
    """
    return h

def main():
  
   data_set = input("Which data set do you want?")
   tuple = getReviews(data_set)
   data_dict = toBeNamedLater(tuple) 
   count = getAllWordCounts(data_dict)
   total_words = getAllTotalWords(data_dict)
   tf = getTF(count,total_words)
   vocab = makeVocab(tf)
   denom = getDenom(count,vocab)
   idf = getIDF(count,denom)
   tf_idf = tfIdf(tf,idf)
   #oh = list(tf_idf.items())[0]
   #print(vocab)
   #print(denom)
   #print(oh)
   #print(len(tf),len(idf),len(tf_idf))
   #print(tf_idf)
   #print(count)
   #print(lexicon)
   '''
   with open('tfidfresults2.txt','w') as f:
        for file_name, dict in tf_idf.items():
            f.write(file_name + '\n')
            f.write("\n".join(["{}: {}".format(word,score) for word,score in dict.items()]) + '\n')
            f.write('\n')
   '''  
   
   with open('tfidf_neg_count_train.txt','w') as f:
        for file_name, dict in count.items():
            f.write(file_name)
            f.write(" ".join([" {} {}".format(word,score) for word,score in dict.items()]) + '\n')
   '''
   with open('vocab_test.txt','w') as f:
        #f.write(" ".join(["{} {} ".format(file_name,count,) for file_name,count in total_words.items()]))
        for k,v in vocab.items():
            f.write("%s %s\n" % (k,v))
  
   '''
main() 


