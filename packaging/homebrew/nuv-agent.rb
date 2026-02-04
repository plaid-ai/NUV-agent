class NuvAgent < Formula
  include Language::Python::Virtualenv

  desc "Nuvion on-device agent"
  homepage "https://github.com/plaid-ai/NUV-agent"
  url "__URL__"
  sha256 "__SHA256__"
  version "0.1.0"
  license "Proprietary"

  depends_on "python@3.12"
  depends_on "gstreamer"
  depends_on "gst-plugins-base"
  depends_on "gst-plugins-good"
  depends_on "gst-plugins-bad"
  depends_on "gst-plugins-ugly"
  depends_on "gst-libav"
  depends_on "gobject-introspection"
  depends_on "pygobject3"

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/1f/f8/55483431f2b2fd015ae6ed4fe62288823ce908437ed49db5a03d15151678/numpy-2.4.2-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "40397bda92382fcec844066efb11f13e1c9a3e2a8e8f318fb72ed8b6db9f60f1"
  end

  resource "python-dotenv" do
    url "https://files.pythonhosted.org/packages/14/1b/a298b06749107c305e1fe0f814c6c74aea7b2f1e10989cb30f544a1b3253/python_dotenv-1.2.1-py3-none-any.whl"
    sha256 "b81ee9561e9ca4004139c6cbba3a238c32b03e4894671e181b671e8cb8425d61"
  end

  resource "websockets" do
    url "https://files.pythonhosted.org/packages/40/1e/9771421ac2286eaab95b8575b0cb701ae3663abf8b5e1f64f1fd90d0a673/websockets-16.0-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "86890e837d61574c92a97496d590968b23c2ef0aeb8a9bc9421d174cd378ae39"
  end

  resource "stomper" do
    url "https://files.pythonhosted.org/packages/1c/f0/e924d61cf68e566f3ed5f83471230453e4e3535e330e65ed4f39cf9dfc5d/stomper-0.4.3-py3-none-any.whl"
    sha256 "e0d157db9bc1d5e2d0356bcd322fa9010d9d02cf403ca97618e8454d2697f0a9"
  end

  resource "aiohttp" do
    url "https://files.pythonhosted.org/packages/5d/43/4be01406b78e1be8320bb8316dc9c42dbab553d281c40364e0f862d5661c/aiohttp-3.13.3-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "27234ef6d85c914f9efeb77ff616dbf4ad2380be0cda40b4db086ffc7ddd1b7d"
  end

  resource "aiohappyeyeballs" do
    url "https://files.pythonhosted.org/packages/0f/15/5bf3b99495fb160b63f95972b81750f18f7f4e02ad051373b669d17d44f2/aiohappyeyeballs-2.6.1-py3-none-any.whl"
    sha256 "f349ba8f4b75cb25c99c5c2d84e997e485204d2902a9597802b0371f09331fb8"
  end

  resource "aiosignal" do
    url "https://files.pythonhosted.org/packages/fb/76/641ae371508676492379f16e2fa48f4e2c11741bd63c48be4b12a6b09cba/aiosignal-1.4.0-py3-none-any.whl"
    sha256 "053243f8b92b990551949e63930a839ff0cf0b0ebbe0597b0f3fb19e1a0fe82e"
  end

  resource "attrs" do
    url "https://files.pythonhosted.org/packages/3a/2a/7cc015f5b9f5db42b7d48157e23356022889fc354a2813c15934b7cb5c0e/attrs-25.4.0-py3-none-any.whl"
    sha256 "adcf7e2a1fb3b36ac48d97835bb6d8ade15b8dcce26aba8bf1d14847b57a3373"
  end

  resource "frozenlist" do
    url "https://files.pythonhosted.org/packages/2b/94/5c8a2b50a496b11dd519f4a24cb5496cf125681dd99e94c604ccdea9419a/frozenlist-1.8.0-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "f833670942247a14eafbb675458b4e61c82e002a148f49e68257b79296e865c4"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/a9/65/1caac9d4cd32e8433908683446eebc953e82d22b03d10d41a5f0fefe991b/multidict-6.7.1-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "b0fa96985700739c4c7853a43c0b3e169360d6855780021bfc6d0f1ce7c123e7"
  end

  resource "propcache" do
    url "https://files.pythonhosted.org/packages/0a/b6/5c9a0e42df4d00bfb4a3cbbe5cf9f54260300c88a0e9af1f47ca5ce17ac0/propcache-0.4.1-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "f048da1b4f243fc44f205dfd320933a951b8d89e0afd4c7cacc762a8b9165207"
  end

  resource "yarl" do
    url "https://files.pythonhosted.org/packages/ba/f5/0601483296f09c3c65e303d60c070a5c19fcdbc72daa061e96170785bc7d/yarl-1.22.0-cp312-cp312-macosx_11_0_arm64.whl"
    sha256 "939fe60db294c786f6b7c2d2e121576628468f65453d86b0fe36cb52f987bd74"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/0e/61/66938bbb5fc52dbdf84594873d5b51fb1f7c7794e9c0f5bd885f30bc507b/idna-3.11-py3-none-any.whl"
    sha256 "771a87f49d9defaf64091e6e6fe9c18d4833f140bd19464795bc32d966ca37ea"
  end

  resource "future" do
    url "https://files.pythonhosted.org/packages/da/71/ae30dadffc90b9006d77af76b393cb9dfbfc9629f339fc1574a1c52e6806/future-1.0.0-py3-none-any.whl"
    sha256 "929292d34f5872e70396626ef385ec22355a1fae8ad29e1a734c3e43f9fbc216"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/18/67/36e9267722cc04a6b9f15c7f3441c2363321a3ea07da7ae0c0707beb2a9c/typing_extensions-4.15.0-py3-none-any.whl"
    sha256 "f0fa19c6845758ab08074a0cfa8b7aecb71c999ca73d62883bc25cc018c4e548"
  end

  def install
    venv = virtualenv_create(libexec, "python3", system_site_packages: true)
    venv.pip_install resources
    venv.pip_install_and_link buildpath
    (etc/"nuv-agent").mkpath

    env = {
      "DYLD_LIBRARY_PATH" => "#{HOMEBREW_PREFIX}/lib",
      "GI_TYPELIB_PATH" => "#{HOMEBREW_PREFIX}/lib/girepository-1.0",
      "GST_PLUGIN_PATH" => "#{HOMEBREW_PREFIX}/lib/gstreamer-1.0",
    }
    real_bin = libexec/"bin/nuv-agent"
    (bin/"nuv-agent").unlink if (bin/"nuv-agent").exist?
    (bin/"nuv-agent").write_env_script(real_bin, env)
  end

  service do
    run [opt_bin/"nuv-agent", "run"]
    keep_alive true
    environment_variables NUV_AGENT_CONFIG: etc/"nuv-agent/agent.env",
                          DYLD_LIBRARY_PATH: "#{HOMEBREW_PREFIX}/lib",
                          GI_TYPELIB_PATH: "#{HOMEBREW_PREFIX}/lib/girepository-1.0",
                          GST_PLUGIN_PATH: "#{HOMEBREW_PREFIX}/lib/gstreamer-1.0"
    log_path var/"log/nuv-agent.log"
    error_log_path var/"log/nuv-agent.log"
  end

  test do
    system bin/"nuv-agent", "config-path"
  end
end
