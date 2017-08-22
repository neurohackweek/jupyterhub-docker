# Generated by Neurodocker v0.2.0-dev.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2017-08-11 19:07:40

FROM neurodebian:stretch-non-free

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="C.UTF-8" \
    LC_ALL="C" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	bzip2 ca-certificates curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir /neurodocker \
    && echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
    && echo 'set +x' >> $ND_ENTRYPOINT \
    && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

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

#--------------------------
# Install FreeSurfer v6.0.0
#--------------------------
# Install version minimized for recon-all
# See https://github.com/freesurfer/freesurfer/issues/70
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc libgomp1 libxmu6 libxt6 tcsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading minimized FreeSurfer ..." \
    && curl -sSL https://dl.dropbox.com/s/nnzcfttc41qvt31/recon-all-freesurfer6-3.min.tgz | tar xz -C /opt \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT
ENV FREESURFER_HOME=/opt/freesurfer

RUN apt-get update -qq && apt-get install -yq --no-install-recommends dcm2niix convert3d ants fsl graphviz tree git-annex-standalone vim emacs-nox nano less ncdu tig git-annex-remote-rclone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# User-defined instruction
RUN sed -i '$iexport SPMMCRCMD="/opt/spm12/run_spm12.sh /opt/mcr/v92/ script"' $ND_ENTRYPOINT

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
    	jupyter jupyterlab traits pandas matplotlib scikit-learn seaborn swig \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate neuro \
    	&& pip install -q --no-cache-dir \
    	https://github.com/nipy/nipype/tarball/master nilearn https://github.com/INCF/pybids/archive/master.zip datalad dipy nipy duecredit pymvpa2" \
    && sync
ENV PATH=/opt/conda/envs/neuro/bin:$PATH

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name afni27 python=2.7 \
    && sync && conda clean -tipsy && sync


#-------------------------
# Set up RStudio
#-------------------------
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		libapparmor1 \
		libedit2 \
		lsb-release \
		;

# You can use rsession from rstudio's desktop package as well.
ARG RSTUDIO_VERSION
RUN RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
    && [ -z "$RSTUDIO_VERSION" ] && RSTUDIO_VERSION=$RSTUDIO_LATEST || true \
    && echo $RSTUDIO_VERSION \
    && wget -q http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb \
    && dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb \
    && rm rstudio-server-*-amd64.deb

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install git+https://github.com/jupyterhub/nbserverproxy.git
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy

RUN pip install git+https://github.com/jupyterhub/nbrsessionproxy.git
RUN jupyter serverextension enable --sys-prefix --py nbrsessionproxy
RUN jupyter nbextension install    --sys-prefix --py nbrsessionproxy
RUN jupyter nbextension enable     --sys-prefix --py nbrsessionproxy

# The desktop package uses /usr/lib/rstudio/bin
ENV PATH="${PATH}:/usr/lib/rstudio-server/bin"
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"/usr/lib/R/lib:/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server:/opt/conda/lib/R/lib"

WORKDIR /home/neuro
