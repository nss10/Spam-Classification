%Replacethe trainPath and testPath with the folder paths of the folder
%locations.

trainPath = "C:\Users\siu856384425\OneDrive - Southern Illinois University\Fa19\Machine Learning\HW2\emailspam\emailspam\train";
testPath = "C:\Users\siu856384425\OneDrive - Southern Illinois University\Fa19\Machine Learning\HW2\emailspam\emailspam\test";

% Number of words to consider while generating the classification model
len_reg_words = 20000;
len_spm_words = 20000;

%Getting top words from both Regular and spam sections and generating a
%wordCount Dictionary(Hashmap)
reg_fileNames = getFileNames(trainPath,'regular');
topReqularWords = getMostFrequentWords(trainPath,reg_fileNames,len_reg_words);
regularWordDict = containers.Map(topReqularWords(:,1),double(topReqularWords(:,2)));

spm_filenames = getFileNames(trainPath,'spam');
topSpamWords = getMostFrequentWords(trainPath,spm_filenames,len_spm_words);
spamWordDict = containers.Map(topSpamWords(:,1),double(topSpamWords(:,2)));

% Initializing some helping variables
fileNames = [reg_fileNames;spm_filenames];
n_reg = length(reg_fileNames);
n_spm = length(spm_filenames);
n = n_reg + n_spm;

%List of all unique words in the entire trianing dataset
uniqueWordList = unique([topReqularWords;topSpamWords]);
m =  length(uniqueWordList);

%Testing logic%
% Fetching words from emails given in the test set
test_fileNames = getFileNames(testPath);
n_test = length(test_fileNames);

result = zeros(n_test,1);  % Result vector which predicts the category and returns 1 for regular and 0 for spam
i=1;
for filename = test_fileNames'
    wordList = getMostFrequentWords(testPath,filename,50);
    m_wordList = length(wordList);
    
    
    % Computing the product of all the words using Naive Bayes 
    % - For % Regular emails 
    reg = 1;
    for word = wordList(:,1)'
        if(isKey(regularWordDict,word))
            reg = reg * (regularWordDict(word)+1);
        end
    end
    reg = reg / ((double(regularWordDict.Count) + m)^m_wordList);
    
    % - For % Spam emails
    spm = 1;
    for word = wordList(:,1)'
        if(isKey(spamWordDict,word))
            spm = spm * (spamWordDict(word)+1);
        end
    end
    spm = spm / ((double(spamWordDict.Count) + m)^m_wordList);
    
    %Returns 1 if probability of reg is greater than spm
    result(i) = reg>spm;
    i=i+1;
end

% Comparing the result values with actual values.
y = zeros(n_test,1);
for i = 1:length(y)
    y(i) = contains(test_fileNames(i),"-");
end
accuracy = sum(result==y)/length(y)





 function frequentWords = getMostFrequentWords(path, fileNames,max)
 %Returns a N X 2 matrix of top 'max' words present in the given filenames
 %and their word count in the overall list of files. 
    wordList =[];
    for filename = fileNames'
        wordList = [wordList; getWordsFromFile(path,filename)];
    end
    %The following lines generates a hashmap of words and their count
    [uniqueWords jj uniqueIndices] = unique(wordList);
    uniqueWordDict = [uniqueWords num2cell(accumarray(uniqueIndices,1))];
    
    [sortedKeys, sortIdx] = sort( double(uniqueWordDict(:,2)),'descend');
    sortedValues = uniqueWordDict( sortIdx,1 );
    frequentWords = [sortedValues sortedKeys];
    if(length(frequentWords)>max)
        frequentWords = frequentWords(1:max,:);
    end
end

%Returns the contents of a file in the form of a string after eliminating
%some special symbols using regex
function str = getFileContents(path, filename)
    if(pwd~=path)
        cd(path);
    end
    %disp(filename);
    text = importdata(filename);
    if(string(class(text)) == "struct")
        text = text.textdata;
    end
    str = regexprep([text{:,1}],'[_<>,.:@"--?/)(]+','');
end


% Returns a list of all filenames present in a given path
%input_type is a param that can be used to specify whether we need spam or
%regular emails from the folder
function fileNames = getFileNames(path,input_type)
    if ~exist('input_type','var')
        regex='*';
    elseif(input_type=="regular")
        regex="*-*";
    elseif(input_type=="spam")
        regex = "spm*";
    else
        regex = "*";
    end
    
    if(pwd~=path)
        cd(path);
    end
    filenameList = string(struct2cell(dir(regex))); %*-*
    fileNames = filenameList(1,:);
    fileNames = fileNames(fileNames~="." & fileNames~="..")';  %Eliminating . and .. from list
end


%Generates a list of all words from a file in the order that they appear in.
function wordList = getWordsFromFile(path, filename)
    str = getFileContents(path, filename);
    if(str=="")
        wordList = [];
        return;
    end
    wordList = lower(string(strsplit(str)))';
end

