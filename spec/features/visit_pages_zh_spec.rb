# TODO fix Chinese language tests
# require 'rails_helper'
#
# describe "For Chinese language user" do
#
#   before (:each) do
#     # @user = FactoryGirl.create(:user)
#     I18n.locale = :zh
#   end
#
#   describe "viewing homepage" do
#
#     it "shows page" do
#       visit root_url
#
#       expect(page).to have_title("得到该键")
#       expect(page).to have_text("的英语内容")
#     end
#   end
#
#   describe "viewing Properties page" do
#
#     it "shows page" do
#       visit properties_url
#
#       expect(page).to have_title("所有属性")
#       expect(page).to have_text("所有属性")
#     end
#   end
#
#   describe "viewing For Sale page" do
#
#     it "shows page" do
#       visit for_sale_index_url
#
#       expect(page).to have_title("出售")
#       expect(page).to have_text("出售")
#     end
#   end
#
#   describe "viewing For Rent page" do
#
#     it "shows page" do
#       visit for_rent_index_url
#
#       expect(page).to have_title("出租")
#       expect(page).to have_text("出租")
#     end
#   end
#
#   describe "viewing Searches page" do
#
#     it "shows page" do
#       visit searches_url
#
#       expect(page).to have_title("搜索")
#       expect(page).to have_text("物业搜索")
#     end
#   end
#
#   describe "viewing Legal page" do
#
#     it "shows page" do
#       visit legal_index_path
#
#       expect(page).to have_title("法律")
#       expect(page).to have_text("律师让我们进来，他们把这个有点气味，并付出了太多太多")
#     end
#   end
#
#   describe "viewing Cookie Policy page" do
#
#     it "shows page" do
#       visit cookie_policy_index_url
#
#       expect(page).to have_title("政策")
#       expect(page).to have_text("律师让我们进来，他们把这个有点气味，并付出了太多太多")
#     end
#   end
#
#   describe "viewing How It Works page" do
#
#     it "shows page" do
#       visit how_it_works_url
#
#       expect(page).to have_text("它是如何工作")
#       expect(page).to have_text("通过做一些工作，为您节省正常成本。面板任意板任意高度。")
#     end
#   end
#
#   describe "viewing About Us page" do
#
#     it "shows page" do
#       visit about_us_url
#
#       expect(page).to have_title("关于我们")
#       expect(page).to have_text("通过做一些工作，可以节省的正常成本")
#     end
#   end
#
#   describe "viewing Contact Us page" do
#
#     it "shows page" do
#       visit contact_us_url
#
#       expect(page).to have_title("联系我们")
#       expect(page).to have_text("取得联系！")
#     end
#   end
#
#   describe "viewing Blog page" do
#
#     it "shows page" do
#       visit blog_index_url
#
#       expect(page).to have_title("博客")
#       expect(page).to have_text("博客文章标题")
#     end
#   end
#
#   describe "viewing Register page" do
#
#     it "shows page" do
#       visit new_user_registration_path
#
#       expect(page).to have_title("注册")
#       expect(page).to have_text("注册")
#     end
#   end
#
#   describe "viewing Sign in page" do
#
#     it "shows page" do
#       visit new_user_session_path
#
#       expect(page).to have_title("登录")
#       expect(page).to have_text("登录")
#     end
#   end
#
#   describe "viewing Sign as administrator in page" do
#
#     it "shows page" do
#       visit new_admin_session_path
#
#       expect(page).to have_title("以管理员身份登录")
#       expect(page).to have_text("以管理员身份登录")
#     end
#   end
#
#   describe "viewing Forgot your password page" do
#
#     it "shows page" do
#       visit 'http://localhost:3000/users/password/new'
#
#       expect(page).to have_title("忘记密码")
#       expect(page).to have_text("忘记密码")
#     end
#   end
# # this test is only applicable for when :confirmable module is included
# #describe "viewing Resend confirmation instructions page" do
# #
# #  it "shows page" do
# #    visit 'http://localhost:3000/users/confirmation/new'
# #
# #    expect(page).to have_text("Resend confirmation instructions")
# #  end
# #end
#
#   describe "viewing Resend unlock instructions page" do
#
#     it "shows page" do
#       visit 'http://localhost:3000/users/unlock/new'
#
#       expect(page).to have_title("重发解锁指令")
#       expect(page).to have_text("重发解锁指令")
#     end
#
#   end
#
# end