# GED
The Method For Group Evolution Discovery In Social Networks

The continuous interest in the social network area contributes to the fast development of this field. The new possibilities of obtaining and storing data facilitate deeper analysis of the entire network, extracted social group and single individuals as well. One of the most interesting research topic is the dynamics of social group, it means analysis of Group Evolution over time. Having appropriate knowledge and methods for dynamic analysis, one may attempt to predict the future of the group and then manage it properly in order to achieve or change this predicted future according to specific needs. Such ability would be a powerful tool in the hands of human resource managers, personnel recruitment, marketing, etc.

The social Group Evolution consists of individual events and seven types of such changes have been identified in the paper: continuing, shrinking, growing, splitting, merging, dissolving and forming. To enable the analysis of Group Evolution a change indicator – inclusion measure was proposed. It has been used in a new method for exploring the evolution of social group, called Group Evolution Discovery (GED).

Introduction to the GED Method can be found in the poster or/and the presentation and/or the following papers:

1. Bródka P., Saganowski S., Kazienko P.: GED: The Method for Group Evolution Discovery in Social Networks, Social Network Analysis and Mining, March 2013, Volume 3, Issue 1, pp 1-14, http://www.springerlink.com/content/d6771886878t8p10/fulltext.pdf
2. Saganowski S., Bródka P., Kazienko P.: Influence of the User Importance Measure on the Group Evolution Discovery Foundations of Computing and Decision Sciences, Volume 37, Issue 4, Pages 293-303, 2012, http://arxiv.org/ftp/arxiv/papers/1301/1301.1534.pdf
3. Saganowski S., Bródka P., Kazienko P.: Influence of the Dynamic Social Network Timeframe Type and Size on the Group Evolution Discovery ASONAM 2012, IEEE Computer Society, 2012, pp. 678-682, http://arxiv.org/ftp/arxiv/papers/1210/1210.5167.pdf
4. Bródka P., Kazienko P, Kołoszczyk B.: Predicting Group Evolution in the Social Network SocInfo 2012, LNCS 7710, pp. 54–67, 2012, http://arxiv.org/ftp/arxiv/papers/1210/1210.5161.pdf

The repository includes the MS SQL Script with GED method - V_0.1 (2011)
1. Split your social network into timeframes
2. For each timeframe calculate the communities (extract groups) using any group detection method. The GED method was tested for Clique Percolation Method and The Louvain Method
3. For each group and each timeframe calculate the user importance measure e.g. degree centrality, betweenness centrality, closeness centrality, page rank, social position, etc.
4. Create a new database in Microsoft SQL Server, download and run the SQL script
5. ort your data into Groups_with_importance_measure table
6. cute the GED procedure e.g. EXEC [dbo].[GED]
7.  results can be found in GED_evolution table
8. lyse and enjoy :)

GED implementationin Python (https://github.com/iit-Demokritos/community-Tracking-GED) Diakidis, Georgios, et al. who used GED in the article Predicting the evolution of communities in social networks Proceedings of the 5th International Conference on Web Intelligence, Mining and Semantics. ACM, 2015.
