# Jupyterhub for Neurohackweek

Docker configuration

https://hub.docker.com/r/arokem/jupyterhub-docker/


Constructed using:

```
docker run --rm kaczmarj/neurodocker generate -b neurodebian:zesty-non-free -p apt \
--instruction "RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -" \
--install dcm2niix convert3d ants graphviz tree git-annex-standalone vim emacs-nox nano less ncdu tig git-annex-remote-rclone xvfb mesa-utils build-essential nodejs \
--fsl version=5.0.10 \
--freesurfer version=6.0.0 min=true \
--spm version=12 matlab_version=R2017a \
--install psmisc libapparmor1 sudo r-recommended libssl1.0.0 \
--instruction "RUN bash -c \"curl http://download2.rstudio.org/rstudio-server-\$(curl https://s3.amazonaws.com/rstudio-server/current.ver)-amd64.deb >> rstudio-server-amd64.deb && dpkg -i rstudio-server-amd64.deb && rm rstudio-server-amd64.deb\" " \
--instruction "RUN curl -sSL https://dl.dropbox.com/s/lfuppfhuhi1li9t/cifti-data.tgz?dl=0 | tar zx -C / " \
--afni version=latest \
--user=neuro \
--miniconda python_version=3.6 \
            conda_install="jupyter jupyterlab traits pandas matplotlib scikit-learn seaborn swig reprozip reprounzip altair traitsui apptools configobj vtk jupyter_contrib_nbextensions bokeh scikit-image codecov nitime cython joblib jupyterhub=0.7.2" \
            env_name="neuro" \
            pip_install="https://github.com/nipy/nibabel/archive/master.zip https://github.com/nipy/nipype/tarball/master nilearn https://github.com/INCF/pybids/archive/master.zip datalad dipy nipy duecredit pymvpa2 mayavi git+https://github.com/jupyterhub/nbrsessionproxy.git https://github.com/poldracklab/mriqc/tarball/master https://github.com/poldracklab/fmriprep/tarball/master pprocess " \
--instruction "RUN bash -c \"source activate neuro && python -m ipykernel install --sys-prefix --name neuro --display-name Py3-neuro \" " \
--instruction "RUN bash -c \"source activate neuro && pip install --pre --upgrade ipywidgets pythreejs \" " \
--instruction "RUN bash -c \"source activate neuro && pip install  --upgrade https://github.com/maartenbreddels/ipyvolume/archive/master.zip && jupyter nbextension install --py --sys-prefix ipyvolume && jupyter nbextension enable --py --sys-prefix ipyvolume \" " \
--instruction "RUN bash -c \"source activate neuro && jupyter nbextension enable rubberband/main && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main \" " \
--instruction "RUN bash -c \"source activate neuro && jupyter serverextension enable --sys-prefix --py nbrsessionproxy && jupyter nbextension install --sys-prefix --py nbrsessionproxy && jupyter nbextension enable --sys-prefix --py nbrsessionproxy \" " \
--instruction "RUN bash -c \" source activate neuro && pip install git+https://github.com/data-8/gitautosync && jupyter serverextension enable --py nbgitautosync --sys-prefix \" " \
--miniconda python_version=2.7 \
            env_name="afni27" \
            conda_install="ipykernel" \
            add_to_path=False \
--instruction "RUN bash -c \"source deactivate && source activate afni27 && python -m ipykernel install --sys-prefix --name afni27 --display-name Py2-afni && source deactivate \" " \
--instruction "RUN bash -c \"source activate neuro && python -c 'from nilearn import datasets; haxby_dataset = datasets.fetch_haxby()' \" " \
--user=root \
--instruction "RUN mkdir /data && chown neuro /data" \
--user=neuro \
--instruction "RUN bash -c \"source activate neuro && cd /data && datalad install -r ///workshops/nih-2017/ds000114 && datalad get -r -J4 ds000114/sub-0[12] && datalad get -r ds000114/derivatives/f*/sub-0[12] && datalad get -r ds000114/derivatives/f*/fsaverage5 \" " \
--workdir /home/neuro \
--instruction "ENV PATH=\"\${PATH}:/usr/lib/rstudio-server/bin\" " \
--instruction "ENV LD_LIBRARY_PATH=\"/usr/lib/R/lib:\${LD_LIBRARY_PATH}\" " \
--no-check-urls > Dockerfile
```
