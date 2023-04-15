The Cloud Resume Challenge Project
The cloud resume challenge by Forrest brazeal exposes aspiring Cloud Engineers to the career by building fundamental skills and introducing them to tools used in the cloud environment. This project helps to showcase technical skills rather than just certifications (which is a requirement for the project).
The cloud resume challenge is a 16-step outline to deploy a static website using any cloud provider. The project fosters self-learning as it doesn’t provide instructions but just a guideline, the challenge really pushed me to make a lot of research, debugging, and implementation as it introduces a lot of new terms such as infrastructure as code, testing, CI/CD which I was totally oblivious to. The project makes use of serverless cloud architectures which is the core of the project;
S3
CloudFront
Amazon Route53
Cloudfront and Certificate Manager
Lambda Function
Dynamodb
API Gateway
Building the Front-End
I already had a resume written with Google Docs, although not with so much experience anyways, the challenge required that the resume be written in HTML and CSS of which I had very little knowledge, and since the challenge was not about web dev, I opted for a resume template by ceevee which I used for my frontend. I do plan on building some Frontend skills by writing my own resume HTML and CSS code some other time after the challenge. Check template HERE.
Building the Static Website
This section involved hosting a static website using S3 bucket and Route53 while using CloudFront for content delivery and secured connection to the website (i.e https), I also created an SSL certificate using AWS Certificate Manager.
This section was pretty easy though, I had to register a domain for the website and because I had a very skinny budget there was Namecheap.com to the rescue (got a domain for less than $2), hosted the domain on Route53 (NS, A, CNAME Records).
I uploaded the resume code to the S3 bucket and made it private making sure only Cloudfront could retrieve items from the bucket using Origin Access Control (OAC). The Route53 A record points at the CloudFront Endpoint URL which retrieves the index.html from the S3 bucket.
AWS has very good documentation on this check it HERE.
Building the Backend
I got the resume website up and running which was the easy part, now on to the complex part. The B part of the challenge was to make a visitor counter that registers the number of visitors that have opened or visited the website.
Dynamodb: The count had to be stored and retrieved from a database (here I used Dyanmodb), each time the website opens the count in the database increases by 1 and the current value is represented on the website.
Lambda function: The lambda function updates the count value in the database and also gets/retrieves the count value from the DB, each time the website loads this lambda function is triggered and runs the code in it. I wrote a Python code for the lambda function using boto3. Ensure to give your function CRUD permission to dynamodb.
API Gateway: API helps to connect your code to a part of a service. For my resume website to retrieve the count value from dynamodb it had to connect to the lambda function and dynamodb. it needed an API for this connection, I created a REST API in API Gateway which acts as a trigger for the lambda function.
I had to write a little bit of javascript to call the API invoke URL. If you have never ever heard of CORS (Cross-Origin-Resource-Sharing), it can be a real pain in the butt, I had to battle with that for a while before I could get it all up and running. You have to enable CORS on the API gateway and also make sure that your lambda function returns the correct headers and status code or you gon be banging your head so hard trying to figure out what’s wrong. AWS does has a great documentation on that also.
Infrastructure-as-Code
Now I have a fully functional resume website that displays the visitor count on each visit. To set this all up I had to use the console, CLI command, and SDK, to automate the provisioning of these structures, I use Terraform. The challenge said to use AWS SAM but I opted for Terraform since it is cloud agnostic and can also be used for other providers. To make sure my terraform code was working properly I deleted the structures I created earlier and recreated them using the terraform code and it felt like magic
CI/CD (Frontend and Backend)
I created two different GitHub repositories for the Frontend and Backend. The frontend repo houses the resume code (HTML, CSS, JS) and Terraform config file while the backend repo houses the lambda function code, the unit test, and Terraform config file.
I set up GitHub Actions (CI/CD) for both repos such that for the Frontend, any change made locally once it’s pushed to GitHub, the action runs a job that syncs the S3 contents and also invalidates Cloudfront cache. For the Backend, any change made locally once it’s pushed to GitHub runs a job that runs a unit test, if the unit test passes it applies any changes made and updates the actual resources.
And with this, all set I was done with the project HERE is the final feel of it. I’ll be making some much more updates on this, for now, I’m just focused on getting hands-on with projects. For my next project, I’ll be using traditional architectures for this same challenge. Do follow along.
You can find all my codes in my GitHub repo, Frontend, and Backend, please feel free to make comments on any observations.

