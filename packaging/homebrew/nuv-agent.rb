class NuvAgent < Formula
  include Language::Python::Virtualenv

  desc "Nuvion on-device agent"
  homepage "https://github.com/plaid-ai/NUV-agent"
  url "__URL__"
  sha256 "__SHA256__"
  version "0.1.1"
  license "Proprietary"

  depends_on "python@3.14"
  depends_on "gstreamer"
  depends_on "gst-plugins-base"
  depends_on "gst-plugins-good"
  depends_on "gst-plugins-bad"
  depends_on "gst-plugins-ugly"
  depends_on "gst-libav"
  depends_on "gobject-introspection"
  depends_on "pygobject3"

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/25/7a/1fee4329abc705a469a4afe6e69b1ef7e915117747886327104a8493a955/numpy-2.4.2-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "d1240d50adff70c2a88217698ca844723068533f3f5c5fa6ee2e3220e3bdb000"
  end

  resource "python-dotenv" do
    url "https://files.pythonhosted.org/packages/14/1b/a298b06749107c305e1fe0f814c6c74aea7b2f1e10989cb30f544a1b3253/python_dotenv-1.2.1-py3-none-any.whl"
    sha256 "b81ee9561e9ca4004139c6cbba3a238c32b03e4894671e181b671e8cb8425d61"
  end

  resource "websockets" do
    url "https://files.pythonhosted.org/packages/bb/f4/d3c9220d818ee955ae390cf319a7c7a467beceb24f05ee7aaaa2414345ba/websockets-16.0-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "fd3cb4adb94a2a6e2b7c0d8d05cb94e6f1c81a0cf9dc2694fb65c7e8d94c42e4"
  end

  resource "stomper" do
    url "https://files.pythonhosted.org/packages/1c/f0/e924d61cf68e566f3ed5f83471230453e4e3535e330e65ed4f39cf9dfc5d/stomper-0.4.3-py3-none-any.whl"
    sha256 "e0d157db9bc1d5e2d0356bcd322fa9010d9d02cf403ca97618e8454d2697f0a9"
  end

  resource "aiohttp" do
    url "https://files.pythonhosted.org/packages/e8/0b/b97660c5fd05d3495b4eb27f2d0ef18dc1dc4eff7511a9bf371397ff0264/aiohttp-3.13.3-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "c685f2d80bb67ca8c3837823ad76196b3694b0159d232206d1e461d3d434666f"
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
    url "https://files.pythonhosted.org/packages/a1/93/72b1736d68f03fda5fdf0f2180fb6caaae3894f1b854d006ac61ecc727ee/frozenlist-1.8.0-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "4970ece02dbc8c3a92fcc5228e36a3e933a01a999f7094ff7c23fbd2beeaa67c"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/f1/4f/733c48f270565d78b4544f2baddc2fb2a245e5a8640254b12c36ac7ac68e/multidict-6.7.1-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "0e161ddf326db5577c3a4cc2d8648f81456e8a20d40415541587a71620d7a7d1"
  end

  resource "propcache" do
    url "https://files.pythonhosted.org/packages/b2/fa/89a8ef0468d5833a23fff277b143d0573897cf75bd56670a6d28126c7d68/propcache-0.4.1-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "9f302f4783709a78240ebc311b793f123328716a60911d667e0c036bc5dcbded"
  end

  resource "yarl" do
    url "https://files.pythonhosted.org/packages/11/63/ff458113c5c2dac9a9719ac68ee7c947cb621432bcf28c9972b1c0e83938/yarl-1.22.0-cp314-cp314-macosx_11_0_arm64.whl"
    sha256 "594fcab1032e2d2cc3321bb2e51271e7cd2b516c7d9aee780ece81b07ff8244b"
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
    python = Formula["python@3.14"].opt_bin/"python3.14"
    venv = virtualenv_create(libexec, python, system_site_packages: true)

    resources.each do |r|
      r.stage do
        wheel = Dir["*.whl"].first
        target = wheel ? Pathname.pwd/wheel : Pathname.pwd
        system python, "-m", "pip", "--python=#{venv.root}/bin/python", "install",
               "--no-deps", "--ignore-installed", "--no-compile", "--only-binary=:all:", target
      end
    end

    system python, "-m", "pip", "--python=#{venv.root}/bin/python", "install",
           "--no-deps", "--ignore-installed", "--no-compile", buildpath
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
