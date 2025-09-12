#include "keyATM_base.h"

using namespace Eigen;
using namespace Rcpp;
using namespace std;


void keyATMbase::initialize_specific()
{
  TRACE_FUNC();
  nv_alpha = priors_list["alpha"];
  alpha = Rcpp::as<Eigen::VectorXd>(nv_alpha);

  estimate_alpha = options_list["estimate_alpha"];
  if (estimate_alpha == 0) {
    store_alpha = 0;
  } else {
    store_alpha = 1;
  }
}

void keyATMbase::resume_initialize_specific()
{
  estimate_alpha = options_list["estimate_alpha"];
  if (estimate_alpha == 0) {
    nv_alpha = priors_list["alpha"];
    alpha = Rcpp::as<Eigen::VectorXd>(nv_alpha);
    store_alpha = 0;
  } else {
    List alpha_iter = stored_values["alpha_iter"];
    NumericVector alpha_rvec = alpha_iter[alpha_iter.size() - 1];  // last estimated alpha
    alpha = Rcpp::as<Eigen::VectorXd>(alpha_rvec);
    store_alpha = 1;
  }
}

// add here
#include <Rcpp.h>
using Rcpp::IntegerVector;

static inline void rprint_iv(const char *name, const IntegerVector &v, int max_elems = 20)
{
  const int n = v.size();
  const int lim = (n < max_elems) ? n : max_elems;
  Rprintf("%s (len=%d) [", name, n);
  for (int i = 0; i < lim; ++i)
  {
    if (i)
      Rprintf(", ");
    Rprintf("%d", v[i]);
  }
  if (n > lim)
    Rprintf(", ...");
  Rprintf("]\n");
}

void keyATMbase::iteration_single(int it)
{ // Single iteration
  TRACE_FUNC();
  int doc_id_;
  int doc_length;
  int w_, z_, s_;
  int new_z, new_s;
  int w_position;

  doc_indexes = sampler::shuffled_indexes(num_doc); // shuffle

  for (int ii = 0; ii < num_doc; ++ii) {
    // doc_id_ = doc_indexes[ii];
    doc_id_ = ii;
    doc_s = S[doc_id_], doc_z = Z[doc_id_], doc_w = W[doc_id_];
    doc_length = doc_each_len[doc_id_];

    // add here
    // Rprintf("it=%d  ii=%d  doc_id_=%d  doc_length=%d\n", it, ii, doc_id_, doc_length);
    // rprint_iv("S", doc_s);
    // rprint_iv("Z", doc_z);
    // rprint_iv("W", doc_w);

    token_indexes = sampler::shuffled_indexes(doc_length); //shuffle

    // Rcpp::List Zz = model["Z"];     // Z 是一个 list
    // Rcpp::IntegerVector Z0 = Zz[0]; // 取第 1 个文档
    // printf("during1 iteration_single model Z[0] %d %d %d\n",
    //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印

    // Iterate each word in the document
    for (int jj = 0; jj < doc_length; ++jj) {
      w_position = token_indexes[jj];
      s_ = doc_s[w_position], z_ = doc_z[w_position], w_ = doc_w[w_position];

      // Rcpp::List Zz = model["Z"];     // Z 是一个 list
      // Rcpp::IntegerVector Z0 = Zz[0]; // 取第 1 个文档
      // printf("during11 iteration_single model Z[0] %d %d %d\n",
      //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印
      new_z = sample_z(alpha, z_, s_, w_, doc_id_);

      // Zz = model["Z"];     // Z 是一个 list
      // Z0 = Zz[0]; // 取第 1 个文档
      // printf("during12 iteration_single model Z[0] %d %d %d\n",
      //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印
      doc_z[w_position] = new_z;
      // if(jj < 5)
      // {
      //   printf("WWW: ii%d jj%d, w_%d new_z%d a%d\n", ii, jj, w_, new_z, keywords[new_z].find(w_) == keywords[new_z].end());
      // } else {
      //   while(1) {
      //     printf("");
      //   }
      // }
      if (keywords[new_z].find(w_) == keywords[new_z].end())
        continue;

      z_ = doc_z[w_position]; // use updated z
      new_s = sample_s(z_, s_, w_, doc_id_);
      doc_s[w_position] = new_s;

      // Zz = model["Z"]; // Z 是一个 list
      // Z0 = Zz[0];      // 取第 1 个文档
      // printf("during13 iteration_single model Z[0] %d %d %d\n",
      //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印

      checkUserInterrupt();
    }

    Z[doc_id_] = doc_z;
    S[doc_id_] = doc_s;

    // Check keybord interruption to cancel the iteration
    // Zz = model["Z"];     // Z 是一个 list
    // Z0 = Zz[0]; // 取第 1 个文档
    // printf("during2 iteration_single model Z[0] %d %d %d\n",
    //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印
  }

  // Check keybord interruption to cancel the iteration
  // Rcpp::List Zz = model["Z"];     // Z 是一个 list
  // Rcpp::IntegerVector Z0 = Zz[0]; // 取第 1 个文档
  // printf("after iteration_single model Z[0] %d %d %d\n",
  //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印

  sample_parameters(it);

  // Check keybord interruption to cancel the iteration
  // Zz = model["Z"];     // Z 是一个 list
  // Z0 = Z[0]; // 取第 1 个文档
  // printf("after2 iteration_single model Z[0] %d %d %d\n",
  //        Z0[0], Z0[1], Z0[2]); // 用 printf 打印

  // while (1)
  // {
  //   printf("");
  // }
}

void keyATMbase::sample_parameters(int it)
{
  TRACE_FUNC();
  if (estimate_alpha)
    sample_alpha();

  // Store alpha
  if (store_alpha) {
    int r_index = it + 1;
    if (r_index % thinning == 0 || r_index == 1 || r_index == iter) {
      NumericVector alpha_rvec = alpha_reformat(alpha, num_topics);
      List alpha_iter = stored_values["alpha_iter"];
      alpha_iter.push_back(alpha_rvec);
      stored_values["alpha_iter"] = alpha_iter;
    }
  }
}

void keyATMbase::sample_alpha()
{
  TRACE_FUNC();

  double start, end, previous_p, new_p, newlikelihood, slice_;
  keep_current_param = alpha;
  topic_ids = sampler::shuffled_indexes(num_topics);
  newalphallk = 0.0;
  int k;

  for (int i = 0; i < num_topics; ++i) {
    k = topic_ids[i];
    store_loglik = alpha_loglik(k);
    start = min_v ; // shrinked with shrinkp()
    end = max_v;  // shrinked with shrinkp()

    previous_p = alpha(k) / (1.0 + alpha(k)); // shrinkp
    slice_ = store_loglik - 2.0 * log(1.0 - previous_p)
            + log(unif_rand()); // <-- using R random uniform

    for (int shrink_time = 0; shrink_time < max_shrink_time; ++shrink_time) {
      new_p = sampler::slice_uniform(start, end); // <-- using R function above
      alpha(k) = new_p / (1.0 - new_p); // expandp

      newalphallk = alpha_loglik(k);
      newlikelihood = newalphallk - 2.0 * log(1.0 - new_p);

      if (slice_ < newlikelihood) {
        break;
      } else if (previous_p < new_p) {
        end = new_p;
      } else if (new_p < previous_p) {
        start = new_p;
      } else {
        Rcpp::stop("Something goes wrong in sample_lambda_slice().");
        alpha(k) = keep_current_param(k);
        break;
      }
    }
  }
}

double keyATMbase::alpha_loglik(int k)
{
  TRACE_FUNC();
  double loglik = 0.0;
  double fixed_part = 0.0;

  ndk_a = n_dk.rowwise() + alpha.transpose(); // Use Eigen Broadcasting
  double alpha_sum_val = alpha.sum();


  fixed_part += mylgamma(alpha_sum_val); // first term numerator
  fixed_part -= mylgamma(alpha(k)); // first term denominator
  // Add prior
  if (k < keyword_k) {
    loglik += gammapdfln(alpha(k), eta_1, eta_2);
  } else {
    loglik += gammapdfln(alpha(k), eta_1_regular, eta_2_regular);
  }

  for (int d = 0; d < num_doc; ++d) {
    loglik += fixed_part;

    // second term numerator
    loglik += mylgamma(ndk_a(d,k));

    // second term denominator
    loglik -= mylgamma(doc_each_len_weighted[d] + alpha_sum_val);
  }

  return loglik;
}

double keyATMbase::loglik_total()
{
  TRACE_FUNC();
  double loglik = 0.0;
  double fixed_part = 0.0;

  for (int k = 0; k < num_topics; ++k) {
    for (int v = 0; v < num_vocab; ++v) { // word
      loglik += mylgamma(beta + n_s0_kv(k, v) ) - mylgamma(beta);
    }

    // word normalization
    loglik += mylgamma( beta * (double)num_vocab ) - mylgamma(beta * (double)num_vocab + n_s0_k(k) );

    if (k < keyword_k) {
      // For keyword topics

      // n_s1_kv
      for (SparseMatrix<double,RowMajor>::InnerIterator it(n_s1_kv, k); it; ++it) {
        loglik += mylgamma(beta_s + it.value()) - mylgamma(beta_s);
      }
      loglik += mylgamma( beta_s * (double)keywords_num[k] ) - mylgamma(beta_s * (double)keywords_num[k] + n_s1_k(k) );

      // Normalization
      loglik += mylgamma( prior_gamma(k, 0) + prior_gamma(k, 1)) - mylgamma( prior_gamma(k, 0)) - mylgamma( prior_gamma(k, 1));

      // s
      loglik += mylgamma( n_s0_k(k) + prior_gamma(k, 1) )
                - mylgamma(n_s1_k(k) + prior_gamma(k, 0) + n_s0_k(k) + prior_gamma(k, 1))
                + mylgamma(n_s1_k(k) + prior_gamma(k, 0));
    }
  }

  // z
  fixed_part = alpha.sum();
  for (int d = 0; d < num_doc; ++d) {
    loglik += mylgamma( fixed_part ) - mylgamma( doc_each_len_weighted[d] + fixed_part );

    for (int k = 0; k < num_topics; ++k) {
      loglik += mylgamma( n_dk(d,k) + alpha(k) ) - mylgamma( alpha(k) );
    }
  }

  return loglik;
}
