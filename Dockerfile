# Generated by Neurodocker v0.3.0-dev0.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2017-08-24 01:53:48

FROM neurodebian:stretch-non-free

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	bzip2 ca-certificates curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
         && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

# User-defined instruction
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -

RUN apt-get update -qq && apt-get install -yq --no-install-recommends dcm2niix convert3d ants graphviz tree git-annex-standalone vim emacs-nox nano less ncdu tig git-annex-remote-rclone xvfb mesa-utils build-essential nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--------------------
# Install AFNI latest
#--------------------
ENV PATH=/opt/afni:$PATH
RUN apt-get update -qq && apt-get install -yq --no-install-recommends ed gsl-bin libglu1-mesa-dev libglib2.0-0 libglw1-mesa \
    libgomp1 libjpeg62 libxm4 netpbm tcsh xfonts-base xvfb \
    && libs_path=/usr/lib/x86_64-linux-gnu \
    && if [ -f $libs_path/libgsl.so.19 ]; then \
           ln $libs_path/libgsl.so.19 $libs_path/libgsl.so.0; \
       fi \
    # Install libxp (not in all ubuntu/debian repositories) \
    && apt-get install -yq --no-install-recommends libxp6 \
    || /bin/bash -c " \
       curl --retry 5 -o /tmp/libxp6.deb -sSL http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
       && dpkg -i /tmp/libxp6.deb && rm -f /tmp/libxp6.deb" \
    # Install libpng12 (not in all ubuntu/debian repositories) \
    && apt-get install -yq --no-install-recommends libpng12-0 \
    || /bin/bash -c " \
       curl -o /tmp/libpng12.deb -sSL http://mirrors.kernel.org/debian/pool/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
       && dpkg -i /tmp/libpng12.deb && rm -f /tmp/libpng12.deb" \
    # Install R \
    && apt-get install -yq --no-install-recommends \
    	r-base-dev r-cran-rmpi \
     || /bin/bash -c " \
        curl -o /tmp/install_R.sh -sSL https://gist.githubusercontent.com/kaczmarj/8e3792ae1af70b03788163c44f453b43/raw/0577c62e4771236adf0191c826a25249eb69a130/R_installer_debian_ubuntu.sh \
        && /bin/bash /tmp/install_R.sh" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni \
    && curl -sSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar zx -C /opt/afni --strip-components=1 \
    && /opt/afni/rPkgsInstall -pkgs ALL \
    && rm -rf /tmp/*

#-----------------------------------------------------------
# Install FSL v5.0.10
# FSL is non-free. If you are considering commerical use
# of this Docker image, please consult the relevant license:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence
#-----------------------------------------------------------
RUN echo "Downloading FSL ..." \
    && curl -sSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-centos6_64.tar.gz \
    | tar zx -C /opt \
    && /bin/bash /opt/fsl/etc/fslconf/fslpython_install.sh -q -f /opt/fsl \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT
ENV FSLDIR=/opt/fsl \
    PATH=/opt/fsl/bin:$PATH

#--------------------------
# Install FreeSurfer v6.0.0
#--------------------------
# Install version minimized for recon-all
# See https://github.com/freesurfer/freesurfer/issues/70
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc libgomp1 libxmu6 libxt6 tcsh perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading minimized FreeSurfer ..." \
    && curl -sSL https://dl.dropbox.com/s/nnzcfttc41qvt31/recon-all-freesurfer6-3.min.tgz | tar xz -C /opt \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT
ENV FREESURFER_HOME=/opt/freesurfer

#----------------------
# Install MCR and SPM12
#----------------------
# Install MATLAB Compiler Runtime
RUN apt-get update -qq && apt-get install -yq --no-install-recommends libxext6 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -sSL -o /tmp/mcr.zip https://www.mathworks.com/supportfiles/downloads/R2017a/deployment_files/R2017a/installers/glnxa64/MCR_R2017a_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/mcr -mode silent -agreeToLicense yes \
    && rm -rf /tmp/*

# Install standalone SPM
RUN echo "Downloading standalone SPM ..." \
    && curl -sSL -o spm.zip http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_latest_Linux_R2017a.zip \
    && unzip -q spm.zip -d /opt \
    && chmod -R 777 /opt/spm* \
    && rm -rf spm.zip \
    && /opt/spm12/run_spm12.sh /opt/mcr/v92/ quit \
    && sed -i '$iexport SPMMCRCMD=\"/opt/spm12/run_spm12.sh /opt/mcr/v92/ script\"' $ND_ENTRYPOINT
ENV MATLABCMD=/opt/mcr/v92/toolbox/matlab \
    FORCE_SPMMCR=1 \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/opt/mcr/v92/runtime/glnxa64:/opt/mcr/v92/bin/glnxa64:/opt/mcr/v92/sys/os/glnxa64:$LD_LIBRARY_PATH

RUN apt-get update -qq && apt-get install -yq --no-install-recommends psmisc libapparmor1 sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# User-defined instruction
RUN bash -c "curl http://download2.rstudio.org/rstudio-server-$(curl https://s3.amazonaws.com/rstudio-server/current.ver)-amd64.deb >> rstudio-server-amd64.deb && dpkg -i rstudio-server-amd64.deb && rm rstudio-server-amd64.deb"

# User-defined instruction
RUN curl -sSL https://dl.dropbox.com/s/lfuppfhuhi1li9t/cifti-data.tgz?dl=0 | tar zx -C /

# Create new user: neuro
RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

#------------------
# Install Miniconda
#------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH
RUN echo "Downloading Miniconda installer ..." \
    && miniconda_installer=/tmp/miniconda.sh \
    && curl -sSL -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && /bin/bash $miniconda_installer -f -b -p $CONDA_DIR \
    && rm -f $miniconda_installer \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda update -y -q --all && sync \
    && conda clean -tipsy && sync

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name neuro python=3.6 \
    	jupyter jupyterlab traits pandas matplotlib scikit-learn seaborn swig reprozip reprounzip altair traitsui apptools configobj vtk jupyter_contrib_nbextensions bokeh scikit-image \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate neuro \
    	&& pip install -q --no-cache-dir \
    	https://github.com/nipy/nibabel/archive/master.zip https://github.com/nipy/nipype/tarball/master nilearn https://github.com/INCF/pybids/archive/master.zip datalad dipy nipy duecredit pymvpa2 mayavi git+https://github.com/jupyterhub/nbrsessionproxy.git" \
    && sync
ENV PATH=/opt/conda/envs/neuro/bin:$PATH

# User-defined instruction
RUN bash -c "source activate neuro && python -m ipykernel install --user --name neuro --display-name Py3-neuro "

# User-defined instruction
RUN bash -c "source activate neuro && pip install --pre --upgrade ipywidgets pythreejs "

# User-defined instruction
RUN bash -c "source activate neuro && pip install  --upgrade https://github.com/maartenbreddels/ipyvolume/archive/23eb91685dfcf200ee82f89ab6f7294f9214db8c.zip && jupyter nbextension install --py --sys-prefix ipyvolume && jupyter nbextension enable --py --sys-prefix ipyvolume "

# User-defined instruction
RUN bash -c "source activate neuro && jupyter nbextension enable rubberband/main && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main "

# User-defined instruction
RUN bash -c "source activate neuro && jupyter serverextension enable --sys-prefix --py nbrsessionproxy && jupyter nbextension install --sys-prefix --py nbrsessionproxy && jupyter nbextension enable --sys-prefix --py nbrsessionproxy "

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name afni27 python=2.7 \
    	ipykernel \
    && sync && conda clean -tipsy && sync

# User-defined instruction
RUN bash -c "source activate afni27 && python -m ipykernel install --user --name afni27 --display-name Py2-afni "

# User-defined instruction
RUN bash -c "source activate neuro && python -c 'from nilearn import datasets; haxby_dataset = datasets.fetch_haxby()' "


# The desktop package uses /usr/lib/rstudio/bin
ENV PATH="${PATH}:/usr/lib/rstudio-server/bin"
ENV LD_LIBRARY_PATH="/usr/lib/R/lib:/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server:/opt/conda/lib/R/lib"

WORKDIR /home/neuro

ENTRYPOINT []
