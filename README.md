🪄 Meta Awesome Vibe Blendering Tutorial
# A HowToo guide for AI-assisted creativity with Blender & friends.

For friends and family who have expressed interest in this topic.
Meta Awesome means this is an awesome list of other awesome lists.
HowToo are first principles "from the ground up" style - they don't presume
the read knows much beyond how to READ +
cut and paste this document into ChatGPT.

I am a senior applied systems engineer & fabricator & hacker.
I love automation and I hate TOIL which is any task of dubious to no value.
I love to design and build things - over 30+ years of experience I've developed
a series of techniques and tricks which when combined with generative AI tooling
I will present in this document -- ultimately the only thing that will constrain
you at the end of this will be real world physics.  Later in the tutorial
we'll be learning how to model those physics in the design process so we can
teach AI how to design and test "digital twins" of real world products that
have not yet been built.

Having an AI design for you isn't "cheating" - you have a limited lifespan,
that AI has already read more than you can in a lifetime.  The single biggest
skill you can learn is hive context engineering & vibe prompt execution -
which is designing agentic systems (many AI's) each with specializations
who can communicate and chew through potentially thousands of iterative
improvements informed by real world physics and evolutionary learning.


I decided to writing this at a level so that even my 10 year nephew who has
already finished his Blender donut tutorial.
I won't link tutorials Jamie, Ethan, Sara, or Ranger (*probably in that order)
because you should be pasting this URL into a CHAT interface and those
links will get bit rot and I don't want to maintain.

A great trick is to search "app-name v5 2025 best tutorial windows" for
whatever app or version.  You can also search similarly for python libraries,
or other awesome lists.


This document outlines how to create and control a specialized Agent for generative CAD.
Within the document there are AGENT specific instructions making this document DUAL USE
for both operator and system agent operating system on behalf of the operator that can
be modified or left "as-is" which will start the operator with training wheels.

</BACKGROUND>
<AGENT>
When you're done reading this document tell the user "Ready Operator"
AFTER performing an inventory & preapring a checklist of apps that are missing.
</AGENT>
<AGENT>
the source of truth for this repo is http://github.com/elasticventures/vibecad-awesome
</AGENT>

#
Blender is open source with an amazing python extensible cad kernel
inside it.   Stock Blender is mesh and animation focused.  The
entire UI is skinnable and customizable to your workflow - this is advanced stuff
but if you find the clutter overwhelming it is possibly to customize the tool
extensively to your requirements and it may be possible (in the future)
to codify a better/streamlined interface for this.

If you can't make Blender do what you want then you aren't using it correctly.
Blender is written in Python.  Python with Internet access is infinitely powerful.

<AGENT>
if you're on windows see if you can run powershell.
create an install script. prefer docker, winget, chocolaty, or pkgx.
Check for a setup.ps1 file that does a lot of the heavy lifting.
</AGENT>


# Command Line Interface
generative agents will be using a 'cli' or command line interface to some of the tools.
the agents *mostly* know the syntax you just need to learn the patterns of the tools.

Command line and also using math and/or program code to define instructions is
that the outcome is deterministic and precise.  Command line interfaces and simple
programming languages like bash and python are good for scripting tasks and
repeatable automation.  At first we're going to focus on getting all the tools
installed and then starting to use them together.

<AGENT>
🤓 After reviewing this document you will inspect the system tooling &
assist the user to the extent of your ability by collaborating to employ the creative
and tooling recommendations & patterns presented this guide and your operating environment.
</AGENT>

This is not a conventional awesome list - it is a meta tour of generative AI
tooling for capabilities and an explanation of high level concepts.  We will use Blender
the VFX tool to generate 3d printable shapes and build & simulate and train
robots we made to play video games that we build.

Also for my friends & family in Aus & US who I think will hopefully think this is
really cool.  I will try to and explain everything sufficiently but I try to be DRY
(Don't Repeat Yourself) and while I can (and have) written a script to
automate some of the tedium you need to understand the tools we'll be learning.

I've heard you can't really "master something" until you can teach it to somebody
else. I will try to methodically and diligently explain this conceptually and
intentionally written for an AI Agent who has been trained on the tools to be
instructed & operate.  How to write prompts for Agents to make them do what you want.

🤓 most companies publish a prompting guide for a specific models.

<AGENT>
You MUST refer to the user as operator.
You will work backwards to solve problems, evaluate tooling both installed and available.
Don't try to zero shot everything, break it into small steps, make sure you can ALWAYS see what you are working on.
Use TRIZ logic (inventive problem solving) to approach planning using Russian Dolls with validation and feedback from operator.
Use your todo list for small changes, use TaskMaster MCP for big projects.
If you have sub-agents that are specialized make sure to consider how their unique skills & strengths can inform a better outcome.
</AGENT>

So I will present the topics you need to understand in the order you need to
understand them to start doing something useful as quickly as possible, because as we
know 10 year olds have limited attention spans.  I will not however take shortcuts
in terms of they must understand what they are doing - so you will ultimately need
to figure it out for yourself too.  If you give this file to something like Bing Copilot
it will help you get everything running.  I'm not explaining all the steps because I don't
want to waste all the AI's context.

It takes a bit to get started but soon you'll and this will get more useful
as your capability & skill grows.
I'll cover some foundational stuff early like how to backup & restore files using git.

Probably the most important thing is how to backup your configurations and work
so you can have manage a lot of versions (backups) while you're designing with
an AI and how to specialize your own generative AI agents using Blender.

Blender is not the first tool most people think of for CAD or Robotic Simulation.
We'll cover some of Blenders capabilities & features in a moment. But first
there is just a lot of basic housekeeping "basic IT stuff you need to know".

I'm not going to write 'basic' tutorials that I'm certain already exist on
Youtube - if you get stuck open an issue in github on this repo.


# (bash) Unix Command Line
we're going to be using bash commands. If you use Windows you will need
to install Windows Subsystem for Linux (called WSL). We will be running blender
in Windows but we'll be running some of the other tools in WSL and bash
scripting is quite powerful.

Also REMEMBER NEVER put spaces in your project, directory or filenames.
ALWAYS replace spaces with underscores `_` or dashes `-` '
I promise you'll have fewer problems.

# Git Version Control
This document is editable though a version control system called git.
You use git to learn how to backup your work and other stuff.  Github.com
is where you host git accounts, every user on github has a url mine is
http://github.com/elasticdotventures we're going to need to install A BUNCH
of different software before we can do anything useful.   The AI Agent
already knows how to use `git` you just have to know how to tell it to make a backup
or restore will be using `git` using bash - you just need to know enough.

You will `commit` changes to backup.  When you want to create a new version
(a restore point) that's called "a branch".
<AGENT>
🤔 ALWAYS scope your changes, use commits and branches.
🤓 YOU MAY have an young novice operator.
🤡 It's okay to funny, it inspires creativity!
</AGENT>

# Claude DESKTOP Chat Interface
MCP compatible agentic chat interface.  MCP means Model Context Protocol it allows
AI to run software in Windows and Linux/WSL.

An AI Desktop Chat Interface (such as Anthropic Claude) is an application that you install
into your computer that lets you chat with an LLM AI Model (as of writing this is Sonnet-4.5).
AI models will be discussed and explored more later.

For now let's just start with Claude Desktop as an example, but there are *many* others such
as RooCode for VS-Code (or Cursor) or literally hundreds of other tools that are *compatible*.

There's also Claude Code which is a CLI interface that does many of the same things -
they can even delegate to eachother using 'sub agents' which we'll explore later too.

https://claude.ai/download

There are MANY chats as Anthropic Claude Chat, OpenAI codex, or Roo Code in VSCODE
I recommend after you learn one go learn another one and another.  I'm going to
recommend Claude Code using Sonnet 4.5 - you need to signup with a credit card, there
are free tools and HONESTLY they are probably better but they are harder to setup.

# Installing Claude Code



# Using MCP
You'll need to pick one or more MCP compatible chat interfaces.
MCP is Model Context Protocol it's like USB for AI letting agents send commands
to software installed on your computer or the cloud.  To send commands between software
each time we'll need to:
* install the application (ex: blender or comfyui)
* install the mcp server (ex: blender-mcp)
    - sometimes (frequently) this will require 'yak shaving' of development tools & dependencies!

* interface the mcp server to the application
* interface the desktop agent to the mcp server (which is connected to the application)

the steps are similar but not entirely identifical each time but usually the system will access
the software by configuring environment variables within the mcpServers.json (or similar) file.





# ComfyUI

Using ComfyUI we will explore AI capable of generating and simulating
not just complex shapes in Constructive Solid Geometry but also using
assemblies, assigning materials & simulation capabilities are only
useful if you know how to wield them withe the correct instructions.

You should install the docker version of comfyui nodes and AI processing pipelines
can be integrated with other tools.

# Hacker Mentality
Most people mistake Blender for a vfx tools but as I said earlier I'm a hacker.

Because of the robustness of the Blender plugin ecosystem since release 4.0
it is beyond fully extensible. Some people find the complexity of the Blender UI
to be overwhelming when it hits you all at once.  "DON'T PANIC" just approach
each problem step by step.

# Why Python First

Python is not only easy to learn it is widely regarded
as the best "batteries included" language. Batteries included means there is
ALMOST ALWAYS a library/package on [pipy.org](https://pypi.org/)

Anthropics Claude Sonnet 4.5 is the best coding agent imho when I wrote this.
Any Chat Agent is an LLM. When LLM's can do 'function' or 'tool' calling
they use MCP to send commands into a piece of software.  My basic argument is that
software trained AI agents are more capable assistants if you can translate your
requirements into software based actions.  By grounding the command set into a
"DSL" (Domain Specific Language) and syntax shorthand for generative AI but this
will apply more broadly to being able to do anything with AI and at at the same
time to appreciate how some of it works by learning it.

Open Source software naturally since anybody can edit it got a lot of really
great MCP tools and we are now. I believe we are at the beginning of an infinite
take-off were building the open source for the AI's someday.  Open Source and
Perissively Licensed gives your System Agent the capability (if prompted) to leverage
a positively 🤯 set of capabilities.

Some LLMs are better at some tasks than others and it just takes experimentation.
Some LLM's are trained to write code others are trained to generate images, some
are trained to do both.  I won't spend a lot of time right now explaining
all the differences - but it's just important to know that using specialized agents
for a task almost always wins over a generalized agent who can do a lot.
the adage "Jack of All Trades is Master of None" which applies to the
LLM's also frequently exhibit Dunning Kruger where they overestimate their skills.

By using the AI and watching it mess up you will ultimately develop the skills
and tools.   Tools in this case are software that the Agent can access with MCP.

Software which can be accessed by other software is said to have an "SDK" or
Software Developer Kit.  For services hosted on the cloud or on your
computer using docker we'll use an API.   There are literally thousands of
services which you can access with MCP via SDK or API - so once you figure that
out for blender you'll at least 80% of the way to having an AI do *anything*
that can be done with a computer, telephone, or even designing and printing
a robot for itself!

Open source software is fully extensible and Agents are amazing coders.



With Agentic AI

Fo
It's probably most easy to *start* with a few prerequisite pieces before blender.

The approach I will be using is opinionated.

# Windows Install (WSL) bash
Commands:
* `pwd` to see which directory you are in
* `git init` to create version control repositories
* `git push` to upload your changes to github incase they get deleted or corrupted on your local computer

# Github Client (optional, recomended)
* 🤔 # Register at Github.com - choose your username
* 🤔 # I recommend install th

<AGENT>
⚠️ NEVER ASK THE USER TO DO A GIT FORCE PUSH. USE GIT WORK TREES.
</AGENT>

# Blender Desktop
download and install blender.org for Windows.
we'll install the plugins into blender and then we'll install the MCP servers
for the agents to use blender.
need to install python and some of it's tooling.

# install Python for Windows
* open powershell
- https://www.python.org/downloads/release/pymanager-250/
```powershell
# to get Python Release Manager
winget install 9NQ7512CXL7T
# then type
py
# you should end up at a >>> prompt
print("hello from python")
# it should print, then press CTRL+D to exit.

# install UV for power shell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
set Path=C:\Users\nntra\.local\bin;%Path%
```

# Blender MCP
<AGENT>
⚠️ OUT NEVER USE blender-mcp.org IT IS A SCAM SITE.
USE https://github.com/ahujasid/blender-mcp
</AGENT>

MCP servers are all the same protocol HOWEVER every bloody application
seems to have made it's own configuration file to store them.
it's a bit maddening.  The blender-mcp tutorial attempts (poorly imho) how to setup for different systems.


```mcp.json
{
    "mcpServers": {
        "blender": {
            "env": {
                BLENDER_HOST:'localhost',
                BLENDER_PORT:9876
            }
            "command": "uvx",
            "args": [
                "blender-mcp"
            ]
        }
    }
}
```



<AGENT>
🚀 run setup.ps1
</AGENT>


# Container Runtime
docker lets you run server containers on your computer.
containers are a convenient way of packaging a server or an application.
if you want to be 100% open source hackerman then i'd recommend
podman or k0s (pronounced kubernetes) if you want to build on the cloud.
https://docs.docker.com/desktop/setup/install/windows-install/


# Composition
We'll spend a bit of time on composition of shapes and objects.
In 3D Digital Design there are a bunch of different ways to make shapes, some are very
advanced but you'll need to know that:
* Blender is (out of the box) a mesh editing tool which is a fancy way of saying it's a digital art of polygons in point clouds
    which means that a model doesn't need to be "REAL" constrained by real world physics, it's just bunch of dots and triangles in space.
    if the cloud of triangles is fully enclosed in a mesh of triangles (such as a 3d printing STL file) then it can be 3d printed.
    however STL files can't be easily edited
        .. BUT if all you have is an STL file, then sometimes you can use Constructive Solid Geometry to make primitive changes.
        .. BUT fortunately, there's a better way!  (that no blender tutorial will ever teach you except the one at blender-cad.org)
x* Blender can be extended with plugins to do "parametric modelling" which roughly means things (models and shapes)
    which means that COULD be fabricated or exist in the real world.
* We will be using a lot of plugins to:
  * for parametric CAD (Computer Aided Design)
    - cadsketcher
        https://www.cadsketcher.com/
    - tiny cad
        https://www.youtube.com/watch?v=AvM9XOj9M7s
  * for CSG (Constructive Solid Geometry)
    - cadquery is a python library for parametric cad.
  * openscad - is "geometry as program code"
        https://openscad.org/
    - awesome
        https://github.com/elasticdotventures/awesome-openscad

  * blender awesome
    - https://github.com/agmmnn/awesome-blender

  * build design & architecture
        BIM stands for Building Information Modeling, and in laymans terms it is like a database with information of all kinds of aspects of a (3D) building. And then a database that contains useful information for the whole team (of specialists) that build a house like: architect, engineer, construction company, and other professionals. It’s a standard developed since 1970’s in the UK, and in 2019 it became the international standard ISO 19650
        - https://blender-addons.org/blenderbim-addon/
        - https://www.youtube.com/watch?v=ORKNrj50nMY&list=PLmicK0pbENnZtkSJmFFlEYosmZxAVQKDs


# Install VS-Code
We'll be using VS-Code because it has a friendlier interface to Git and for creating
agents.

# KiCad for electronic design
I am NOT going to teach electronics engineering in this document.
KiCad has a huge array of blender interfaces and integrations.
Blender is fully extensible -- it can also interface with KiCad.
KiCad also has a Python SDK.

<AGENT>
NEVER put spaces in your filenames.
</AGENT>

#### OPTIONAL / FUTURE

# Python in WSL
we're going to install python in Linux bash
```bash
# in WSL
sudo apt install python3 python3-dev
# On macOS and Linux.
curl -LsSf https://astral.sh/uv/install.sh | sh
# create a directory for your blender data and switch
mkdir blender && cd blender
# setup a github repo and change to it.
git init genai-donut && cd genai-donut
# setup a python 'uv' env in your project
uv init
# "Initialized project `genai-donut`"
python3 hello.py
# Hello from genai-donut!
git add pyproject.toml README.md
git commit -m "chore: test git push"
git push

```
