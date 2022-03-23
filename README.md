# 2022-TIP-Evaluating-Quantitative-Metrics-of-Tone-Mapped-Images

This code implements the followin paper: I. R. Khan, T. A. Alotaibi, A. Siddiq and F. Bourennani,  "Evaluating Quantitative Metrics of Tone-Mapped Images," IEEE Transactions on Image Processing, vol. 31, pp. 1751-1760, 2022.

Please cite the paper if you use this code.

The code can be used to evaluate tone-mapped image quality assessment (TM_IQA) metrics (such as TMQI, TMQI2, FSITM, BTMQI, or any similar metric that assigns a quality score to the tone-mapped images).

You will provide an HDR image and the metric function. The algorithm will tone-map the HDR image and use the metric to score its quality. Then it will use differential evolution (DE) to enhance the image such that your metric's score will increase. After a few iterations, it will output the initial and the enhanced tone-mapped image with their scores. You can then visually compare the two to verify if the metric's scores represent the true relative quality of both images. 

In most of the cases you will find that the quality of the final image with high score is actually low. In many cases you will see visual artifacts. If this happens, it will show that the metric failed to assign correct scores.

We evaluated six metrics (TMQI, TMQI2, FSITM, BTMQI, NLPD, and VQGC) and all failed in this test. See details in our paper.

You will run main.m file to evaluate a metric. Instruction are provided in the file.
