import re
import math
from collections import Counter,defaultdict



def hasNumbers(inputString):
    return any(char.isdigit() for char in inputString)

def hasLetter(string):
    return re.search('[a-zA-Z]', string)

#print(hasNumbers('-4'))
#print(hasNumbers('5'))
#print(hasNumbers('-'))


file = open('AFINN.txt')
with file as f:
     lexicon = {}
     for line in f:
         line = line.split()
         if line and hasNumbers(line[1]):
            lexicon[line[0]] = int(line[1])
         elif line and hasNumbers(line[2]):
            temp = [line[0],line[1]]
            temp_string = ' '.join(temp)
            lexicon[temp_string] = int(line[2])
         elif line and hasNumbers(line[3]):
            temp = [line[0],line[1],line[2]]
            lexicon[' '.join(temp)] = int(line[3])


#Files I could possibly need to read


#tf-idf scores 'tfidfresultstest.txt' and 
#tf scores 'tfresultstest.txt' and 'tfresultstrain.txt'
#idf results 'idfresultstest.txt' and 'idfresultstrain.txt' 
#word counts 'testcounts.txt' and 'traincounts.txt'
#total word count 'traintotalwordcounts.txt' and 'testtotalwordcounts.txt'

#might have to convert all the values back to ints/floats

#meant to retrieve tf-idf,tf,word counts
def readInScores1(file_name):
    total = {}
    with open(file_name) as f:
         for line in f:
             lines = line.split()
             #turn the rest of a list into a dict
             dict = {lines[i]: float(lines[i + 1]) for i in range(1, len(lines),2)}
             #dict = {lines[0]: {lines[i]: lines[i + 1] for i in range(1,len(lines),2)}} 
             total[lines[0]] = dict
         #print(len(total))
    return total

#meant to retrieve total word counts and idf scores
def readInScores2(file_name):
    total = {}
    with open(file_name) as f:
         for line in f:
             lines = line.split()
             total[lines[0]] = int(lines[1])
    return total
#print(readInScores2('denom.txt'))
#print(readInScores1('testcounts.txt'))
#print(list(lexicon.keys())[list(lexicon.values()).index('working')])
#print(readInScores1('tfidfresults2.txt')['5594_10.txt'])

def getReviews(input):
    neg_dir = ''
    neg_count = ''
    pos_dir = ''
    pos_count = ''
    if input == 'test':
       neg_dir = 'tfidf_neg_test.txt'
       neg_count = 'tfidf_neg_count_test.txt'
       pos_dir = 'tfidf_pos_test.txt'
       pos_count = 'tfidf_pos_count_test.txt'
    elif input == 'train':
       neg_dir = 'tfidf_neg_train.txt'
       neg_count = 'tfidf_neg_count_train.txt'
       pos_dir = 'tfidf_pos_train.txt'
       pos_count = 'tfidf_pos_count_train.txt'
    else:
       print('You entered an invalid input. Please try again.')
    return neg_dir,pos_dir,neg_count,pos_count


#returns the set of all unique words 50,000 documents
def vocab():
    tfidf = readInScores1('tfidfresults2.txt')
    #oh = {}
    oh = {word for dict in tfidf.values() for word,score in dict.items()}
    return oh

#print(len(vocab()))

#print(len(labelTotals()[0]),len(labelTotals()[1]))
#print(testrun2())
#returns a dictionary of the words in each review and sentiment score
'''
def testRun4():
    tfidf = readInScores1('tfidfresultstest.txt')
    oh = {file_name: {word: lexicon.get(word) for word,score in dict.items() if lexicon.get(word) is not None} for file_name,dict in tfidf.items()}  
    return oh
#print(len(testRun4()))
'''
    
#this serves as the prediction function
def computeScores(tfidf):
    #tfidf = readInScores1('tfidfresults2.txt')
    counts = readInScores1('testcounts2.txt')
    scores = dict()
    for file_name,countdict in counts.items():
        total = 0
        for word,count in countdict.items():
            #if lexicon.get(word):
               #total += lexicon[word] * count
            if tfidf.get(file_name):
               total += tfidf[file_name][word] * count
        scores[file_name] = total
    return scores
#computeScores()
#print(computeScores())

#maybe if the first one is wrong??
#weights we're using in naive bayes
def computeScores2():
    tfidf = readInScores1('tfidfresults2.txt')
    counts = readInScores1('testcounts2.txt')
    '''
    for file_name,tfidfdict in tfidf.items():
        total = 0
        for word,score in tfidfdict.items():
            if lexicon.get(word):
               total = lexicon[word] * tfidf[file_name][word]
               #temp[word] = total
               #scores[file_name] = temp
    '''
    #scores = {file_name: {word: lexicon[word] * tfidf[file_name][word] for word,score in tfidfdict.items()} for file_name,tfidfdict in tfidf.items()}
    scores = {file_name: {word: count * tfidf[file_name][word] for word,count in countdict.items()} for file_name,countdict in counts.items()}
    return scores
#print(computeScores2()['5594_10.txt'])
#testRun5()

#prediction function used to classify a review
def prediction(weights,counts):
    #weights = computeScores2()
    #counts = readInScores1('testcounts2.txt')
    #scores = dict()
    #for file_name,weightdict in weights.items():
    total = 0
    for word,count in counts.items():
        if weights.get(word):
           total += weights[word] * count
    return total

#doing the prediction function for every movie review
#takes in weights, a feature vector with weights for every word in movie review
#takes in word counts, a feature vector with counts
def prediction2(weights,counts):
    #counts = readInScores1('testcounts2.txt')
    #counts = readInScores1('tfidf_pos_count_test.txt')
    #counts = readInScores1('tfidf_neg_count_test.txt')
    #weights = computeScores2() #take a weights parameter
    labels = ['positive','negative']
    scores = {file_name: {label: prediction(dict, weights[label][file_name]) for label in labels} for file_name,dict in counts.items()} 
    return scores
#prediction2()

#calculates the smoothed log probability of P(word | label)
#possible weights we could use 
def getpxy(tfidf,word_counts): 
    log_prob = defaultdict(float)
    dict2 = dict()
    vocab1 = vocab()
    smooth_value = 0.1
    v_a = len(vocab1) * smooth_value #smooth value in the denominator
    
    #pos_counts = readInScores2('denom_pos.txt')
    #neg_counts = readInScores2('denom_neg.txt')
    #total_pos = 0
    #total_neg = 0
    total = 0
      
    for word,score in word_counts.items():
        total += score

    log_prob = {file_name: {word: math.log((word_counts[word] + smooth_value)/(total + v_a)) for word in reviews.keys() if word_counts.get(word)} for file_name,reviews in tfidf.items()}
    #log_prob = {file_name: {word: score * lexicon[word] for word,score in reviews.items() if lexicon.get(word)} for file_name,reviews in tfidf.items()}
    return log_prob

#returns dict of positive and negative weights
def estimatenb(tfidf): 
    #tfidf = readInScores1('tfidfresults2.txt')
    #tfidf = readInScores1('tfidf_pos_test.txt')
    #tfidf = readInScores1('tfidf_neg_test.txt')

    pos_counts = readInScores2('denom_pos.txt')
    neg_counts = readInScores2('denom_neg.txt') 
    vocabulary = vocab()

    log_probs = []
    weights = {}
    labels = ['positive','negative'] 
    log_probs.append(pos_counts)
    log_probs.append(neg_counts)
    #label_prob = math.log(1/2)
    
    for log_i,label_i in zip(log_probs,labels):
        pxy = getpxy(tfidf,log_i)
        weights[label_i] = pxy
    return weights
#print(estimatenb())
#print(prediction2(estimatenb()))

#print(test())
#grabs the larger label, classifies review
def argmax(scores):
    new_scores = {}
    for file_name,results in scores.items():
        a = max(results, key=results.get)
        new_scores[file_name] = a
    return new_scores
#print(argmax(getScores()))

#returns a list of classified reviews
def divide_and_conquer(input):
    #change later, these would be parameters
    tfidf_pos = readInScores1(input[1])
    tfidf_neg = readInScores1(input[0])
    data_set = []
     
    pos_counts = readInScores1(input[3])   
    neg_counts = readInScores1(input[2])
    counts = []    

    data_set.append(tfidf_pos)
    data_set.append(tfidf_neg)
    counts.append(pos_counts)
    counts.append(neg_counts) 
    
    final = []
    for i,j in zip(data_set,counts):
       nb = estimatenb(i)
       pred = prediction2(nb,j)
       oh = argmax(pred)
       final.append(oh)
    return final

#print(divide_and_conquer())

#calculates how many reviews were correctly classified
#returns a list
def acc1(input):
    sent = divide_and_conquer(input) #parameter
    labels = ['positive','negative'] #parameter
    counts = []
    
    for i,j in zip(sent,labels):
        total = 0
        for file_name, label in i.items():
            if label == j:
               total += 1
        counts.append(total)
    
    #counts = [total += 1 for i,j in zip(sent,labels) for label in i.values() if label == j]
    return counts

#print(acc1())

def acc2(input):
    #sent = divide_and_conquer() #parameter
    counts = acc1(input) #parameter
    total = sum(counts)
    percent = 100.0 * (total/25000)
    return percent


def main():
    data_set = input('Which data set?')
    reviews = getReviews(data_set)
    percentage = acc2(reviews)    
    print('Classification Accuracy Rate: ',percentage, '%')
          
main()
