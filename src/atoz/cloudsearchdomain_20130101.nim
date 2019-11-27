
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch Domain
## version: 2013-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>You use the AmazonCloudSearch2013 API to upload documents to a search domain and search those documents. </p> <p>The endpoints for submitting <code>UploadDocuments</code>, <code>Search</code>, and <code>Suggest</code> requests are domain-specific. To get the endpoints for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. The domain endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. You submit suggest requests to the search endpoint. </p> <p>For more information, see the <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide">Amazon CloudSearch Developer Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearchdomain/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearchdomain.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearchdomain.ap-southeast-1.amazonaws.com", "us-west-2": "cloudsearchdomain.us-west-2.amazonaws.com", "eu-west-2": "cloudsearchdomain.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearchdomain.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearchdomain.eu-central-1.amazonaws.com", "us-east-2": "cloudsearchdomain.us-east-2.amazonaws.com", "us-east-1": "cloudsearchdomain.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearchdomain.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearchdomain.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearchdomain.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearchdomain.ap-northeast-2.amazonaws.com", "us-west-1": "cloudsearchdomain.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearchdomain.us-gov-east-1.amazonaws.com", "eu-west-3": "cloudsearchdomain.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearchdomain.cn-north-1.amazonaws.com.cn", "sa-east-1": "cloudsearchdomain.sa-east-1.amazonaws.com", "eu-west-1": "cloudsearchdomain.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearchdomain.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearchdomain.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearchdomain.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearchdomain.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearchdomain.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearchdomain.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearchdomain.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearchdomain.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearchdomain.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearchdomain.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearchdomain.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearchdomain.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearchdomain.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearchdomain.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearchdomain.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearchdomain.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearchdomain.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearchdomain.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearchdomain.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearchdomain.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearchdomain.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearchdomain.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearchdomain.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearchdomain.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearchdomain"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_Search_599689 = ref object of OpenApiRestCall_599352
proc url_Search_599691(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Search_599690(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of documents that match the specified search criteria. How you specify the search criteria depends on which query parser you use. Amazon CloudSearch supports four query parsers:</p> <ul> <li><code>simple</code>: search all <code>text</code> and <code>text-array</code> fields for the specified string. Search for phrases, individual terms, and prefixes. </li> <li><code>structured</code>: search specific fields, construct compound queries using Boolean operators, and use advanced features such as term boosting and proximity searching.</li> <li><code>lucene</code>: specify search criteria using the Apache Lucene query parser syntax.</li> <li><code>dismax</code>: specify search criteria using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser.</li> </ul> <p>For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html">Searching Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p> <p>The endpoint for submitting <code>Search</code> requests is domain-specific. You submit search requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   expr: JString
  ##       : <p>Defines one or more numeric expressions that can be used to sort results or specify search or filter criteria. You can also specify expressions as return fields. </p> <p>You specify the expressions in JSON using the form <code>{"EXPRESSIONNAME":"EXPRESSION"}</code>. You can define and use multiple expressions in a search request. For example:</p> <p><code> {"expression1":"_score*rating", "expression2":"(1/rank)*year"} </code> </p> <p>For information about the variables, operators, and functions you can use in expressions, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html#writing-expressions">Writing Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   stats: JString
  ##        : <p>Specifies one or more fields for which to get statistics information. Each specified field must be facet-enabled in the domain configuration. The fields are specified in JSON using the form:</p> <code>{"FIELD-A":{},"FIELD-B":{}}</code> <p>There are currently no options supported for statistics.</p>
  ##   cursor: JString
  ##         : <p>Retrieves a cursor value you can use to page through large result sets. Use the <code>size</code> parameter to control the number of hits to include in each response. You can specify either the <code>cursor</code> or <code>start</code> parameter in a request; they are mutually exclusive. To get the first cursor, set the cursor value to <code>initial</code>. In subsequent requests, specify the cursor value returned in the hits section of the response. </p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html">Paginating Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   partial: JBool
  ##          : Enables partial results to be returned if one or more index partitions are unavailable. When your search index is partitioned across multiple search instances, by default Amazon CloudSearch only returns results if every partition can be queried. This means that the failure of a single search instance can result in 5xx (internal server) errors. When you enable partial results, Amazon CloudSearch returns whatever results are available and includes the percentage of documents searched in the search results (percent-searched). This enables you to more gracefully degrade your users' search experience. For example, rather than displaying no results, you could display the partial results and a message indicating that the results might be incomplete due to a temporary system outage.
  ##   pretty: JString (required)
  ##   sort: JString
  ##       : <p>Specifies the fields or custom expressions to use to sort the search results. Multiple fields or expressions are specified as a comma-separated list. You must specify the sort direction (<code>asc</code> or <code>desc</code>) for each field; for example, <code>year desc,title asc</code>. To use a field to sort results, the field must be sort-enabled in the domain configuration. Array type fields cannot be used for sorting. If no <code>sort</code> parameter is specified, results are sorted by their default relevance scores in descending order: <code>_score desc</code>. You can also sort by document ID (<code>_id asc</code>) and version (<code>_version desc</code>).</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/sorting-results.html">Sorting Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   return: JString
  ##         : Specifies the field and expression values to include in the response. Multiple fields or expressions are specified as a comma-separated list. By default, a search response includes all return enabled fields (<code>_all_fields</code>). To return only the document IDs for the matching documents, specify <code>_no_fields</code>. To retrieve the relevance score calculated for each document, specify <code>_score</code>. 
  ##   highlight: JString
  ##            : <p>Retrieves highlights for matches in the specified <code>text</code> or <code>text-array</code> fields. Each specified field must be highlight enabled in the domain configuration. The fields and options are specified in JSON using the form 
  ## <code>{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}</code>.</p> <p>You can specify the following highlight options:</p> <ul> <li> <code>format</code>: specifies the format of the data in the text field: <code>text</code> or <code>html</code>. When data is returned as HTML, all non-alphanumeric characters are encoded. The default is <code>html</code>. </li> <li> <code>max_phrases</code>: specifies the maximum number of occurrences of the search term(s) you want to highlight. By default, the first occurrence is highlighted. </li> <li> <code>pre_tag</code>: specifies the string to prepend to an occurrence of a search term. The default for HTML highlights is <code>&amp;lt;em&amp;gt;</code>. The default for text highlights is <code>*</code>. </li> <li> <code>post_tag</code>: specifies the string to append to an occurrence of a search term. The default for HTML highlights is <code>&amp;lt;/em&amp;gt;</code>. The default for text highlights is <code>*</code>. </li> </ul> <p>If no highlight options are specified for a field, the returned field text is treated as HTML and the first match is highlighted with emphasis tags: <code>&amp;lt;em&gt;search-term&amp;lt;/em&amp;gt;</code>.</p> <p>For example, the following request retrieves highlights for the <code>actors</code> and <code>title</code> fields.</p> <p> <code>{ "actors": {}, "title": {"format": "text","max_phrases": 2,"pre_tag": "<b>","post_tag": "</b>"} }</code></p>
  ##   q: JString (required)
  ##    : <p>Specifies the search criteria for the request. How you specify the search criteria depends on the query parser used for the request and the parser options specified in the <code>queryOptions</code> parameter. By default, the <code>simple</code> query parser is used to process requests. To use the <code>structured</code>, <code>lucene</code>, or <code>dismax</code> query parser, you must also specify the <code>queryParser</code> parameter. </p> <p>For more information about specifying search criteria, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html">Searching Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   size: JInt
  ##       : Specifies the maximum number of search hits to include in the response. 
  ##   fq: JString
  ##     : <p>Specifies a structured query that filters the results of a search without affecting how the results are scored and sorted. You use <code>filterQuery</code> in conjunction with the <code>query</code> parameter to filter the documents that match the constraints specified in the <code>query</code> parameter. Specifying a filter controls only which matching documents are included in the results, it has no effect on how they are scored and sorted. The <code>filterQuery</code> parameter supports the full structured query syntax. </p> <p>For more information about using filters, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/filtering-results.html">Filtering Matching Documents</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   format: JString (required)
  ##   facet: JString
  ##        : <p>Specifies one or more fields for which to get facet information, and options that control how the facet information is returned. Each specified field must be facet-enabled in the domain configuration. The fields and options are specified in JSON using the form 
  ## <code>{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}</code>.</p> <p>You can specify the following faceting options:</p> <ul> <li> <p><code>buckets</code> specifies an array of the facet values or ranges to count. Ranges are specified using the same syntax that you use to search for a range of values. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-ranges.html"> Searching for a Range of Values</a> in the <i>Amazon CloudSearch Developer Guide</i>. Buckets are returned in the order they are specified in the request. The <code>sort</code> and <code>size</code> options are not valid if you specify <code>buckets</code>.</p> </li> <li> <p><code>size</code> specifies the maximum number of facets to include in the results. By default, Amazon CloudSearch returns counts for the top 10. The <code>size</code> parameter is only valid when you specify the <code>sort</code> option; it cannot be used in conjunction with <code>buckets</code>.</p> </li> <li> <p><code>sort</code> specifies how you want to sort the facets in the results: <code>bucket</code> or <code>count</code>. Specify <code>bucket</code> to sort alphabetically or numerically by facet value (in ascending order). Specify <code>count</code> to sort by the facet counts computed for each facet value (in descending order). To retrieve facet counts for particular values or ranges of values, use the <code>buckets</code> option instead of <code>sort</code>. </p> </li> </ul> <p>If no facet options are specified, facet counts are computed for all field values, the facets are sorted by facet count, and the top 10 facets are returned in the results.</p> <p>To count particular buckets of values, use the <code>buckets</code> option. For example, the following request uses the <code>buckets</code> option to calculate and return facet counts by decade.</p> <p><code> 
  ## {"year":{"buckets":["[1970,1979]","[1980,1989]","[1990,1999]","[2000,2009]","[2010,}"]}} </code></p> <p>To sort facets by facet count, use the <code>count</code> option. For example, the following request sets the <code>sort</code> option to <code>count</code> to sort the facet values by facet count, with the facet values that have the most matching documents listed first. Setting the <code>size</code> option to 3 returns only the top three facet values.</p> <p><code> {"year":{"sort":"count","size":3}} </code></p> <p>To sort the facets by value, use the <code>bucket</code> option. For example, the following request sets the <code>sort</code> option to <code>bucket</code> to sort the facet values numerically by year, with earliest year listed first. </p> <p><code> {"year":{"sort":"bucket"}} </code></p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/faceting.html">Getting and Using Facet Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   q.options: JString
  ##            : <p>Configures options for the query parser specified in the <code>queryParser</code> parameter. You specify the options in JSON using the following form <code>{"OPTION1":"VALUE1","OPTION2":VALUE2"..."OPTIONN":"VALUEN"}.</code></p> <p>The options you can configure vary according to which parser you use:</p> <ul> <li><code>defaultOperator</code>: The default operator used to combine individual terms in the search string. For example: <code>defaultOperator: 'or'</code>. For the <code>dismax</code> parser, you specify a percentage that represents the percentage of terms in the search string (rounded down) that must match, rather than a default operator. A value of <code>0%</code> is the equivalent to OR, and a value of <code>100%</code> is equivalent to AND. The percentage must be specified as a value in the range 0-100 followed by the percent (%) symbol. For example, <code>defaultOperator: 50%</code>. Valid values: <code>and</code>, <code>or</code>, a percentage in the range 0%-100% (<code>dismax</code>). Default: <code>and</code> (<code>simple</code>, <code>structured</code>, <code>lucene</code>) or <code>100</code> (<code>dismax</code>). Valid for: <code>simple</code>, <code>structured</code>, <code>lucene</code>, and <code>dismax</code>.</li> <li><code>fields</code>: An array of the fields to search when no fields are specified in a search. If no fields are specified in a search and this option is not specified, all text and text-array fields are searched. You can specify a weight for each field to control the relative importance of each field when Amazon CloudSearch calculates relevance scores. To specify a field weight, append a caret (<code>^</code>) symbol and the weight to the field name. For example, to boost the importance of the <code>title</code> field over the <code>description</code> field you could specify: <code>"fields":["title^5","description"]</code>. Valid values: The name of any configured field and an optional numeric value greater than zero. Default: All <code>text</code> and <code>text-array</code> fields. Valid for: <code>simple</code>, <code>structured</code>, <code>lucene</code>, and <code>dismax</code>.</li> <li><code>operators</code>: An array of the operators or special characters you want to disable for the simple query parser. If you disable the <code>and</code>, <code>or</code>, or <code>not</code> operators, the corresponding operators (<code>+</code>, <code>|</code>, <code>-</code>) have no special meaning and are dropped from the search string. Similarly, disabling <code>prefix</code> disables the wildcard operator (<code>*</code>) and disabling <code>phrase</code> disables the ability to search for phrases by enclosing phrases in double quotes. Disabling precedence disables the ability to control order of precedence using parentheses. Disabling <code>near</code> disables the ability to use the ~ operator to perform a sloppy phrase search. Disabling the <code>fuzzy</code> operator disables the ability to use the ~ operator to perform a fuzzy search. <code>escape</code> disables the ability to use a backslash (<code>\</code>) to escape special characters within the search string. Disabling whitespace is an advanced option that prevents the parser from tokenizing on whitespace, which can be useful for Vietnamese. (It prevents Vietnamese words from being split incorrectly.) For example, you could disable all operators other than the phrase operator to support just simple term and phrase queries: <code>"operators":["and","not","or", "prefix"]</code>. Valid values: <code>and</code>, <code>escape</code>, <code>fuzzy</code>, <code>near</code>, <code>not</code>, <code>or</code>, <code>phrase</code>, <code>precedence</code>, <code>prefix</code>, <code>whitespace</code>. Default: All operators and special characters are enabled. Valid for: <code>simple</code>.</li> <li><code>phraseFields</code>: An array of the <code>text</code> or <code>text-array</code> fields you want to use for phrase searches. When the terms in the search string appear in close proximity within a field, the field scores higher. You can specify a weight for each field to boost that score. The <code>phraseSlop</code> option controls how much the matches can deviate from the search string and still be boosted. To specify a field weight, append a caret (<code>^</code>) symbol and the weight to the field name. For example, to boost phrase matches in the <code>title</code> field over the <code>abstract</code> field, you could specify: <code>"phraseFields":["title^3", "plot"]</code> Valid values: The name of any <code>text</code> or <code>text-array</code> field and an optional numeric value greater than zero. Default: No fields. If you don't specify any fields with <code>phraseFields</code>, proximity scoring is disabled even if <code>phraseSlop</code> is specified. Valid for: <code>dismax</code>.</li> <li><code>phraseSlop</code>: An integer value that specifies how much matches can deviate from the search phrase and still be boosted according to the weights specified in the <code>phraseFields</code> option; for example, <code>phraseSlop: 2</code>. You must also specify <code>phraseFields</code> to enable proximity scoring. Valid values: positive integers. Default: 0. Valid for: <code>dismax</code>.</li> <li><code>explicitPhraseSlop</code>: An integer value that specifies how much a match can deviate from the search phrase when the phrase is enclosed in double quotes in the search string. (Phrases that exceed this proximity distance are not considered a match.) For example, to specify a slop of three for dismax phrase queries, you would specify <code>"explicitPhraseSlop":3</code>. Valid values: positive integers. Default: 0. Valid for: <code>dismax</code>.</li> <li><code>tieBreaker</code>: When a term in the search string is found in a document's field, a score is calculated for that field based on how common the word is in that field compared to other documents. If the term occurs in multiple fields within a document, by default only the highest scoring field contributes to the document's overall score. You can specify a <code>tieBreaker</code> value to enable the matches in lower-scoring fields to contribute to the document's score. That way, if two documents have the same max field score for a particular term, the score for the document that has matches in more fields will be higher. The formula for calculating the score with a tieBreaker is <code>(max field score) + (tieBreaker) * (sum of the scores for the rest of the matching fields)</code>. Set <code>tieBreaker</code> to 0 to disregard all but the highest scoring field (pure max): <code>"tieBreaker":0</code>. Set to 1 to sum the scores from all fields (pure sum): <code>"tieBreaker":1</code>. Valid values: 0.0 to 1.0. Default: 0.0. Valid for: <code>dismax</code>. </li> </ul>
  ##   q.parser: JString
  ##           : <p>Specifies which query parser to use to process the request. If <code>queryParser</code> is not specified, Amazon CloudSearch uses the <code>simple</code> query parser. </p> <p>Amazon CloudSearch supports four query parsers:</p> <ul> <li> <code>simple</code>: perform simple searches of <code>text</code> and <code>text-array</code> fields. By default, the <code>simple</code> query parser searches all <code>text</code> and <code>text-array</code> fields. You can specify which fields to search by with the <code>queryOptions</code> parameter. If you prefix a search term with a plus sign (+) documents must contain the term to be considered a match. (This is the default, unless you configure the default operator with the <code>queryOptions</code> parameter.) You can use the <code>-</code> (NOT), <code>|</code> (OR), and <code>*</code> (wildcard) operators to exclude particular terms, find results that match any of the specified terms, or search for a prefix. To search for a phrase rather than individual terms, enclose the phrase in double quotes. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-text.html">Searching for Text</a> in the <i>Amazon CloudSearch Developer Guide</i>. </li> <li> <code>structured</code>: perform advanced searches by combining multiple expressions to define the search criteria. You can also search within particular fields, search for values and ranges of values, and use advanced options such as term boosting, <code>matchall</code>, and <code>near</code>. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-compound-queries.html">Constructing Compound Queries</a> in the <i>Amazon CloudSearch Developer Guide</i>. </li> <li> <code>lucene</code>: search using the Apache Lucene query parser syntax. For more information, see <a 
  ## href="http://lucene.apache.org/core/4_6_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#package_description">Apache Lucene Query Parser Syntax</a>. </li> <li> <code>dismax</code>: search using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser. For more information, see <a href="http://wiki.apache.org/solr/DisMaxQParserPlugin#Query_Syntax">DisMax Query Parser Syntax</a>. </li> </ul>
  ##   start: JInt
  ##        : <p>Specifies the offset of the first search hit you want to return. Note that the result set is zero-based; the first result is at index 0. You can specify either the <code>start</code> or <code>cursor</code> parameter in a request, they are mutually exclusive. </p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html">Paginating Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  section = newJObject()
  var valid_599803 = query.getOrDefault("expr")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "expr", valid_599803
  var valid_599804 = query.getOrDefault("stats")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "stats", valid_599804
  var valid_599805 = query.getOrDefault("cursor")
  valid_599805 = validateParameter(valid_599805, JString, required = false,
                                 default = nil)
  if valid_599805 != nil:
    section.add "cursor", valid_599805
  var valid_599806 = query.getOrDefault("partial")
  valid_599806 = validateParameter(valid_599806, JBool, required = false, default = nil)
  if valid_599806 != nil:
    section.add "partial", valid_599806
  assert query != nil, "query argument is necessary due to required `pretty` field"
  var valid_599820 = query.getOrDefault("pretty")
  valid_599820 = validateParameter(valid_599820, JString, required = true,
                                 default = newJString("true"))
  if valid_599820 != nil:
    section.add "pretty", valid_599820
  var valid_599821 = query.getOrDefault("sort")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "sort", valid_599821
  var valid_599822 = query.getOrDefault("return")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "return", valid_599822
  var valid_599823 = query.getOrDefault("highlight")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "highlight", valid_599823
  var valid_599824 = query.getOrDefault("q")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "q", valid_599824
  var valid_599825 = query.getOrDefault("size")
  valid_599825 = validateParameter(valid_599825, JInt, required = false, default = nil)
  if valid_599825 != nil:
    section.add "size", valid_599825
  var valid_599826 = query.getOrDefault("fq")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "fq", valid_599826
  var valid_599827 = query.getOrDefault("format")
  valid_599827 = validateParameter(valid_599827, JString, required = true,
                                 default = newJString("sdk"))
  if valid_599827 != nil:
    section.add "format", valid_599827
  var valid_599828 = query.getOrDefault("facet")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "facet", valid_599828
  var valid_599829 = query.getOrDefault("q.options")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "q.options", valid_599829
  var valid_599830 = query.getOrDefault("q.parser")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = newJString("simple"))
  if valid_599830 != nil:
    section.add "q.parser", valid_599830
  var valid_599831 = query.getOrDefault("start")
  valid_599831 = validateParameter(valid_599831, JInt, required = false, default = nil)
  if valid_599831 != nil:
    section.add "start", valid_599831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599832 = header.getOrDefault("X-Amz-Date")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = nil)
  if valid_599832 != nil:
    section.add "X-Amz-Date", valid_599832
  var valid_599833 = header.getOrDefault("X-Amz-Security-Token")
  valid_599833 = validateParameter(valid_599833, JString, required = false,
                                 default = nil)
  if valid_599833 != nil:
    section.add "X-Amz-Security-Token", valid_599833
  var valid_599834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Content-Sha256", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Algorithm")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Algorithm", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Signature")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Signature", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-SignedHeaders", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Credential")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Credential", valid_599838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599861: Call_Search_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of documents that match the specified search criteria. How you specify the search criteria depends on which query parser you use. Amazon CloudSearch supports four query parsers:</p> <ul> <li><code>simple</code>: search all <code>text</code> and <code>text-array</code> fields for the specified string. Search for phrases, individual terms, and prefixes. </li> <li><code>structured</code>: search specific fields, construct compound queries using Boolean operators, and use advanced features such as term boosting and proximity searching.</li> <li><code>lucene</code>: specify search criteria using the Apache Lucene query parser syntax.</li> <li><code>dismax</code>: specify search criteria using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser.</li> </ul> <p>For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html">Searching Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p> <p>The endpoint for submitting <code>Search</code> requests is domain-specific. You submit search requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ## 
  let valid = call_599861.validator(path, query, header, formData, body)
  let scheme = call_599861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599861.url(scheme.get, call_599861.host, call_599861.base,
                         call_599861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599861, url, valid)

proc call*(call_599932: Call_Search_599689; q: string; expr: string = "";
          stats: string = ""; cursor: string = ""; partial: bool = false;
          pretty: string = "true"; sort: string = ""; `return`: string = "";
          highlight: string = ""; size: int = 0; fq: string = ""; format: string = "sdk";
          facet: string = ""; qOptions: string = ""; qParser: string = "simple";
          start: int = 0): Recallable =
  ## search
  ## <p>Retrieves a list of documents that match the specified search criteria. How you specify the search criteria depends on which query parser you use. Amazon CloudSearch supports four query parsers:</p> <ul> <li><code>simple</code>: search all <code>text</code> and <code>text-array</code> fields for the specified string. Search for phrases, individual terms, and prefixes. </li> <li><code>structured</code>: search specific fields, construct compound queries using Boolean operators, and use advanced features such as term boosting and proximity searching.</li> <li><code>lucene</code>: specify search criteria using the Apache Lucene query parser syntax.</li> <li><code>dismax</code>: specify search criteria using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser.</li> </ul> <p>For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html">Searching Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p> <p>The endpoint for submitting <code>Search</code> requests is domain-specific. You submit search requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ##   expr: string
  ##       : <p>Defines one or more numeric expressions that can be used to sort results or specify search or filter criteria. You can also specify expressions as return fields. </p> <p>You specify the expressions in JSON using the form <code>{"EXPRESSIONNAME":"EXPRESSION"}</code>. You can define and use multiple expressions in a search request. For example:</p> <p><code> {"expression1":"_score*rating", "expression2":"(1/rank)*year"} </code> </p> <p>For information about the variables, operators, and functions you can use in expressions, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html#writing-expressions">Writing Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   stats: string
  ##        : <p>Specifies one or more fields for which to get statistics information. Each specified field must be facet-enabled in the domain configuration. The fields are specified in JSON using the form:</p> <code>{"FIELD-A":{},"FIELD-B":{}}</code> <p>There are currently no options supported for statistics.</p>
  ##   cursor: string
  ##         : <p>Retrieves a cursor value you can use to page through large result sets. Use the <code>size</code> parameter to control the number of hits to include in each response. You can specify either the <code>cursor</code> or <code>start</code> parameter in a request; they are mutually exclusive. To get the first cursor, set the cursor value to <code>initial</code>. In subsequent requests, specify the cursor value returned in the hits section of the response. </p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html">Paginating Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   partial: bool
  ##          : Enables partial results to be returned if one or more index partitions are unavailable. When your search index is partitioned across multiple search instances, by default Amazon CloudSearch only returns results if every partition can be queried. This means that the failure of a single search instance can result in 5xx (internal server) errors. When you enable partial results, Amazon CloudSearch returns whatever results are available and includes the percentage of documents searched in the search results (percent-searched). This enables you to more gracefully degrade your users' search experience. For example, rather than displaying no results, you could display the partial results and a message indicating that the results might be incomplete due to a temporary system outage.
  ##   pretty: string (required)
  ##   sort: string
  ##       : <p>Specifies the fields or custom expressions to use to sort the search results. Multiple fields or expressions are specified as a comma-separated list. You must specify the sort direction (<code>asc</code> or <code>desc</code>) for each field; for example, <code>year desc,title asc</code>. To use a field to sort results, the field must be sort-enabled in the domain configuration. Array type fields cannot be used for sorting. If no <code>sort</code> parameter is specified, results are sorted by their default relevance scores in descending order: <code>_score desc</code>. You can also sort by document ID (<code>_id asc</code>) and version (<code>_version desc</code>).</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/sorting-results.html">Sorting Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   return: string
  ##         : Specifies the field and expression values to include in the response. Multiple fields or expressions are specified as a comma-separated list. By default, a search response includes all return enabled fields (<code>_all_fields</code>). To return only the document IDs for the matching documents, specify <code>_no_fields</code>. To retrieve the relevance score calculated for each document, specify <code>_score</code>. 
  ##   highlight: string
  ##            : <p>Retrieves highlights for matches in the specified <code>text</code> or <code>text-array</code> fields. Each specified field must be highlight enabled in the domain configuration. The fields and options are specified in JSON using the form 
  ## <code>{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}</code>.</p> <p>You can specify the following highlight options:</p> <ul> <li> <code>format</code>: specifies the format of the data in the text field: <code>text</code> or <code>html</code>. When data is returned as HTML, all non-alphanumeric characters are encoded. The default is <code>html</code>. </li> <li> <code>max_phrases</code>: specifies the maximum number of occurrences of the search term(s) you want to highlight. By default, the first occurrence is highlighted. </li> <li> <code>pre_tag</code>: specifies the string to prepend to an occurrence of a search term. The default for HTML highlights is <code>&amp;lt;em&amp;gt;</code>. The default for text highlights is <code>*</code>. </li> <li> <code>post_tag</code>: specifies the string to append to an occurrence of a search term. The default for HTML highlights is <code>&amp;lt;/em&amp;gt;</code>. The default for text highlights is <code>*</code>. </li> </ul> <p>If no highlight options are specified for a field, the returned field text is treated as HTML and the first match is highlighted with emphasis tags: <code>&amp;lt;em&gt;search-term&amp;lt;/em&amp;gt;</code>.</p> <p>For example, the following request retrieves highlights for the <code>actors</code> and <code>title</code> fields.</p> <p> <code>{ "actors": {}, "title": {"format": "text","max_phrases": 2,"pre_tag": "<b>","post_tag": "</b>"} }</code></p>
  ##   q: string (required)
  ##    : <p>Specifies the search criteria for the request. How you specify the search criteria depends on the query parser used for the request and the parser options specified in the <code>queryOptions</code> parameter. By default, the <code>simple</code> query parser is used to process requests. To use the <code>structured</code>, <code>lucene</code>, or <code>dismax</code> query parser, you must also specify the <code>queryParser</code> parameter. </p> <p>For more information about specifying search criteria, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html">Searching Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   size: int
  ##       : Specifies the maximum number of search hits to include in the response. 
  ##   fq: string
  ##     : <p>Specifies a structured query that filters the results of a search without affecting how the results are scored and sorted. You use <code>filterQuery</code> in conjunction with the <code>query</code> parameter to filter the documents that match the constraints specified in the <code>query</code> parameter. Specifying a filter controls only which matching documents are included in the results, it has no effect on how they are scored and sorted. The <code>filterQuery</code> parameter supports the full structured query syntax. </p> <p>For more information about using filters, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/filtering-results.html">Filtering Matching Documents</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   format: string (required)
  ##   facet: string
  ##        : <p>Specifies one or more fields for which to get facet information, and options that control how the facet information is returned. Each specified field must be facet-enabled in the domain configuration. The fields and options are specified in JSON using the form 
  ## <code>{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}</code>.</p> <p>You can specify the following faceting options:</p> <ul> <li> <p><code>buckets</code> specifies an array of the facet values or ranges to count. Ranges are specified using the same syntax that you use to search for a range of values. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-ranges.html"> Searching for a Range of Values</a> in the <i>Amazon CloudSearch Developer Guide</i>. Buckets are returned in the order they are specified in the request. The <code>sort</code> and <code>size</code> options are not valid if you specify <code>buckets</code>.</p> </li> <li> <p><code>size</code> specifies the maximum number of facets to include in the results. By default, Amazon CloudSearch returns counts for the top 10. The <code>size</code> parameter is only valid when you specify the <code>sort</code> option; it cannot be used in conjunction with <code>buckets</code>.</p> </li> <li> <p><code>sort</code> specifies how you want to sort the facets in the results: <code>bucket</code> or <code>count</code>. Specify <code>bucket</code> to sort alphabetically or numerically by facet value (in ascending order). Specify <code>count</code> to sort by the facet counts computed for each facet value (in descending order). To retrieve facet counts for particular values or ranges of values, use the <code>buckets</code> option instead of <code>sort</code>. </p> </li> </ul> <p>If no facet options are specified, facet counts are computed for all field values, the facets are sorted by facet count, and the top 10 facets are returned in the results.</p> <p>To count particular buckets of values, use the <code>buckets</code> option. For example, the following request uses the <code>buckets</code> option to calculate and return facet counts by decade.</p> <p><code> 
  ## {"year":{"buckets":["[1970,1979]","[1980,1989]","[1990,1999]","[2000,2009]","[2010,}"]}} </code></p> <p>To sort facets by facet count, use the <code>count</code> option. For example, the following request sets the <code>sort</code> option to <code>count</code> to sort the facet values by facet count, with the facet values that have the most matching documents listed first. Setting the <code>size</code> option to 3 returns only the top three facet values.</p> <p><code> {"year":{"sort":"count","size":3}} </code></p> <p>To sort the facets by value, use the <code>bucket</code> option. For example, the following request sets the <code>sort</code> option to <code>bucket</code> to sort the facet values numerically by year, with earliest year listed first. </p> <p><code> {"year":{"sort":"bucket"}} </code></p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/faceting.html">Getting and Using Facet Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  ##   qOptions: string
  ##           : <p>Configures options for the query parser specified in the <code>queryParser</code> parameter. You specify the options in JSON using the following form <code>{"OPTION1":"VALUE1","OPTION2":VALUE2"..."OPTIONN":"VALUEN"}.</code></p> <p>The options you can configure vary according to which parser you use:</p> <ul> <li><code>defaultOperator</code>: The default operator used to combine individual terms in the search string. For example: <code>defaultOperator: 'or'</code>. For the <code>dismax</code> parser, you specify a percentage that represents the percentage of terms in the search string (rounded down) that must match, rather than a default operator. A value of <code>0%</code> is the equivalent to OR, and a value of <code>100%</code> is equivalent to AND. The percentage must be specified as a value in the range 0-100 followed by the percent (%) symbol. For example, <code>defaultOperator: 50%</code>. Valid values: <code>and</code>, <code>or</code>, a percentage in the range 0%-100% (<code>dismax</code>). Default: <code>and</code> (<code>simple</code>, <code>structured</code>, <code>lucene</code>) or <code>100</code> (<code>dismax</code>). Valid for: <code>simple</code>, <code>structured</code>, <code>lucene</code>, and <code>dismax</code>.</li> <li><code>fields</code>: An array of the fields to search when no fields are specified in a search. If no fields are specified in a search and this option is not specified, all text and text-array fields are searched. You can specify a weight for each field to control the relative importance of each field when Amazon CloudSearch calculates relevance scores. To specify a field weight, append a caret (<code>^</code>) symbol and the weight to the field name. For example, to boost the importance of the <code>title</code> field over the <code>description</code> field you could specify: <code>"fields":["title^5","description"]</code>. Valid values: The name of any configured field and an optional numeric value greater than zero. Default: All <code>text</code> and <code>text-array</code> fields. Valid for: <code>simple</code>, <code>structured</code>, <code>lucene</code>, and <code>dismax</code>.</li> <li><code>operators</code>: An array of the operators or special characters you want to disable for the simple query parser. If you disable the <code>and</code>, <code>or</code>, or <code>not</code> operators, the corresponding operators (<code>+</code>, <code>|</code>, <code>-</code>) have no special meaning and are dropped from the search string. Similarly, disabling <code>prefix</code> disables the wildcard operator (<code>*</code>) and disabling <code>phrase</code> disables the ability to search for phrases by enclosing phrases in double quotes. Disabling precedence disables the ability to control order of precedence using parentheses. Disabling <code>near</code> disables the ability to use the ~ operator to perform a sloppy phrase search. Disabling the <code>fuzzy</code> operator disables the ability to use the ~ operator to perform a fuzzy search. <code>escape</code> disables the ability to use a backslash (<code>\</code>) to escape special characters within the search string. Disabling whitespace is an advanced option that prevents the parser from tokenizing on whitespace, which can be useful for Vietnamese. (It prevents Vietnamese words from being split incorrectly.) For example, you could disable all operators other than the phrase operator to support just simple term and phrase queries: <code>"operators":["and","not","or", "prefix"]</code>. Valid values: <code>and</code>, <code>escape</code>, <code>fuzzy</code>, <code>near</code>, <code>not</code>, <code>or</code>, <code>phrase</code>, <code>precedence</code>, <code>prefix</code>, <code>whitespace</code>. Default: All operators and special characters are enabled. Valid for: <code>simple</code>.</li> <li><code>phraseFields</code>: An array of the <code>text</code> or <code>text-array</code> fields you want to use for phrase searches. When the terms in the search string appear in close proximity within a field, the field scores higher. You can specify a weight for each field to boost that score. The <code>phraseSlop</code> option controls how much the matches can deviate from the search string and still be boosted. To specify a field weight, append a caret (<code>^</code>) symbol and the weight to the field name. For example, to boost phrase matches in the <code>title</code> field over the <code>abstract</code> field, you could specify: <code>"phraseFields":["title^3", "plot"]</code> Valid values: The name of any <code>text</code> or <code>text-array</code> field and an optional numeric value greater than zero. Default: No fields. If you don't specify any fields with <code>phraseFields</code>, proximity scoring is disabled even if <code>phraseSlop</code> is specified. Valid for: <code>dismax</code>.</li> <li><code>phraseSlop</code>: An integer value that specifies how much matches can deviate from the search phrase and still be boosted according to the weights specified in the <code>phraseFields</code> option; for example, <code>phraseSlop: 2</code>. You must also specify <code>phraseFields</code> to enable proximity scoring. Valid values: positive integers. Default: 0. Valid for: <code>dismax</code>.</li> <li><code>explicitPhraseSlop</code>: An integer value that specifies how much a match can deviate from the search phrase when the phrase is enclosed in double quotes in the search string. (Phrases that exceed this proximity distance are not considered a match.) For example, to specify a slop of three for dismax phrase queries, you would specify <code>"explicitPhraseSlop":3</code>. Valid values: positive integers. Default: 0. Valid for: <code>dismax</code>.</li> <li><code>tieBreaker</code>: When a term in the search string is found in a document's field, a score is calculated for that field based on how common the word is in that field compared to other documents. If the term occurs in multiple fields within a document, by default only the highest scoring field contributes to the document's overall score. You can specify a <code>tieBreaker</code> value to enable the matches in lower-scoring fields to contribute to the document's score. That way, if two documents have the same max field score for a particular term, the score for the document that has matches in more fields will be higher. The formula for calculating the score with a tieBreaker is <code>(max field score) + (tieBreaker) * (sum of the scores for the rest of the matching fields)</code>. Set <code>tieBreaker</code> to 0 to disregard all but the highest scoring field (pure max): <code>"tieBreaker":0</code>. Set to 1 to sum the scores from all fields (pure sum): <code>"tieBreaker":1</code>. Valid values: 0.0 to 1.0. Default: 0.0. Valid for: <code>dismax</code>. </li> </ul>
  ##   qParser: string
  ##          : <p>Specifies which query parser to use to process the request. If <code>queryParser</code> is not specified, Amazon CloudSearch uses the <code>simple</code> query parser. </p> <p>Amazon CloudSearch supports four query parsers:</p> <ul> <li> <code>simple</code>: perform simple searches of <code>text</code> and <code>text-array</code> fields. By default, the <code>simple</code> query parser searches all <code>text</code> and <code>text-array</code> fields. You can specify which fields to search by with the <code>queryOptions</code> parameter. If you prefix a search term with a plus sign (+) documents must contain the term to be considered a match. (This is the default, unless you configure the default operator with the <code>queryOptions</code> parameter.) You can use the <code>-</code> (NOT), <code>|</code> (OR), and <code>*</code> (wildcard) operators to exclude particular terms, find results that match any of the specified terms, or search for a prefix. To search for a phrase rather than individual terms, enclose the phrase in double quotes. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-text.html">Searching for Text</a> in the <i>Amazon CloudSearch Developer Guide</i>. </li> <li> <code>structured</code>: perform advanced searches by combining multiple expressions to define the search criteria. You can also search within particular fields, search for values and ranges of values, and use advanced options such as term boosting, <code>matchall</code>, and <code>near</code>. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-compound-queries.html">Constructing Compound Queries</a> in the <i>Amazon CloudSearch Developer Guide</i>. </li> <li> <code>lucene</code>: search using the Apache Lucene query parser syntax. For more information, see <a 
  ## href="http://lucene.apache.org/core/4_6_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#package_description">Apache Lucene Query Parser Syntax</a>. </li> <li> <code>dismax</code>: search using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser. For more information, see <a href="http://wiki.apache.org/solr/DisMaxQParserPlugin#Query_Syntax">DisMax Query Parser Syntax</a>. </li> </ul>
  ##   start: int
  ##        : <p>Specifies the offset of the first search hit you want to return. Note that the result set is zero-based; the first result is at index 0. You can specify either the <code>start</code> or <code>cursor</code> parameter in a request, they are mutually exclusive. </p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html">Paginating Results</a> in the <i>Amazon CloudSearch Developer Guide</i>.</p>
  var query_599933 = newJObject()
  add(query_599933, "expr", newJString(expr))
  add(query_599933, "stats", newJString(stats))
  add(query_599933, "cursor", newJString(cursor))
  add(query_599933, "partial", newJBool(partial))
  add(query_599933, "pretty", newJString(pretty))
  add(query_599933, "sort", newJString(sort))
  add(query_599933, "return", newJString(`return`))
  add(query_599933, "highlight", newJString(highlight))
  add(query_599933, "q", newJString(q))
  add(query_599933, "size", newJInt(size))
  add(query_599933, "fq", newJString(fq))
  add(query_599933, "format", newJString(format))
  add(query_599933, "facet", newJString(facet))
  add(query_599933, "q.options", newJString(qOptions))
  add(query_599933, "q.parser", newJString(qParser))
  add(query_599933, "start", newJInt(start))
  result = call_599932.call(nil, query_599933, nil, nil, nil)

var search* = Call_Search_599689(name: "search", meth: HttpMethod.HttpGet,
                              host: "cloudsearchdomain.amazonaws.com", route: "/2013-01-01/search#format=sdk&pretty=true&q",
                              validator: validate_Search_599690, base: "/",
                              url: url_Search_599691,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_Suggest_599973 = ref object of OpenApiRestCall_599352
proc url_Suggest_599975(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Suggest_599974(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves autocomplete suggestions for a partial query string. You can use suggestions enable you to display likely matches before users finish typing. In Amazon CloudSearch, suggestions are based on the contents of a particular text field. When you request suggestions, Amazon CloudSearch finds all of the documents whose values in the suggester field start with the specified query string. The beginning of the field must match the query string to be considered a match. </p> <p>For more information about configuring suggesters and retrieving suggestions, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html">Getting Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p> <p>The endpoint for submitting <code>Suggest</code> requests is domain-specific. You submit suggest requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   pretty: JString (required)
  ##   q: JString (required)
  ##    : Specifies the string for which you want to get suggestions.
  ##   size: JInt
  ##       : Specifies the maximum number of suggestions to return. 
  ##   format: JString (required)
  ##   suggester: JString (required)
  ##            : Specifies the name of the suggester to use to find suggested matches.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `pretty` field"
  var valid_599976 = query.getOrDefault("pretty")
  valid_599976 = validateParameter(valid_599976, JString, required = true,
                                 default = newJString("true"))
  if valid_599976 != nil:
    section.add "pretty", valid_599976
  var valid_599977 = query.getOrDefault("q")
  valid_599977 = validateParameter(valid_599977, JString, required = true,
                                 default = nil)
  if valid_599977 != nil:
    section.add "q", valid_599977
  var valid_599978 = query.getOrDefault("size")
  valid_599978 = validateParameter(valid_599978, JInt, required = false, default = nil)
  if valid_599978 != nil:
    section.add "size", valid_599978
  var valid_599979 = query.getOrDefault("format")
  valid_599979 = validateParameter(valid_599979, JString, required = true,
                                 default = newJString("sdk"))
  if valid_599979 != nil:
    section.add "format", valid_599979
  var valid_599980 = query.getOrDefault("suggester")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = nil)
  if valid_599980 != nil:
    section.add "suggester", valid_599980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Content-Sha256", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Algorithm")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Algorithm", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Signature")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Signature", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-SignedHeaders", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599988: Call_Suggest_599973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves autocomplete suggestions for a partial query string. You can use suggestions enable you to display likely matches before users finish typing. In Amazon CloudSearch, suggestions are based on the contents of a particular text field. When you request suggestions, Amazon CloudSearch finds all of the documents whose values in the suggester field start with the specified query string. The beginning of the field must match the query string to be considered a match. </p> <p>For more information about configuring suggesters and retrieving suggestions, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html">Getting Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p> <p>The endpoint for submitting <code>Suggest</code> requests is domain-specific. You submit suggest requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ## 
  let valid = call_599988.validator(path, query, header, formData, body)
  let scheme = call_599988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599988.url(scheme.get, call_599988.host, call_599988.base,
                         call_599988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599988, url, valid)

proc call*(call_599989: Call_Suggest_599973; q: string; suggester: string;
          pretty: string = "true"; size: int = 0; format: string = "sdk"): Recallable =
  ## suggest
  ## <p>Retrieves autocomplete suggestions for a partial query string. You can use suggestions enable you to display likely matches before users finish typing. In Amazon CloudSearch, suggestions are based on the contents of a particular text field. When you request suggestions, Amazon CloudSearch finds all of the documents whose values in the suggester field start with the specified query string. The beginning of the field must match the query string to be considered a match. </p> <p>For more information about configuring suggesters and retrieving suggestions, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html">Getting Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p> <p>The endpoint for submitting <code>Suggest</code> requests is domain-specific. You submit suggest requests to a domain's search endpoint. To get the search endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p>
  ##   pretty: string (required)
  ##   q: string (required)
  ##    : Specifies the string for which you want to get suggestions.
  ##   size: int
  ##       : Specifies the maximum number of suggestions to return. 
  ##   format: string (required)
  ##   suggester: string (required)
  ##            : Specifies the name of the suggester to use to find suggested matches.
  var query_599990 = newJObject()
  add(query_599990, "pretty", newJString(pretty))
  add(query_599990, "q", newJString(q))
  add(query_599990, "size", newJInt(size))
  add(query_599990, "format", newJString(format))
  add(query_599990, "suggester", newJString(suggester))
  result = call_599989.call(nil, query_599990, nil, nil, nil)

var suggest* = Call_Suggest_599973(name: "suggest", meth: HttpMethod.HttpGet,
                                host: "cloudsearchdomain.amazonaws.com", route: "/2013-01-01/suggest#format=sdk&pretty=true&q&suggester",
                                validator: validate_Suggest_599974, base: "/",
                                url: url_Suggest_599975,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadDocuments_599991 = ref object of OpenApiRestCall_599352
proc url_UploadDocuments_599993(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UploadDocuments_599992(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Posts a batch of documents to a search domain for indexing. A document batch is a collection of add and delete operations that represent the documents you want to add, update, or delete from your domain. Batches can be described in either JSON or XML. Each item that you want Amazon CloudSearch to return as a search result (such as a product) is represented as a document. Every document has a unique ID and one or more fields that contain the data that you want to search and return in results. Individual documents cannot contain more than 1 MB of data. The entire batch cannot exceed 5 MB. To get the best possible upload performance, group add and delete operations in batches that are close the 5 MB limit. Submitting a large volume of single-document batches can overload a domain's document service. </p> <p>The endpoint for submitting <code>UploadDocuments</code> requests is domain-specific. To get the document endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p> <p>For more information about formatting your data for Amazon CloudSearch, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/preparing-data.html">Preparing Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. For more information about uploading data for indexing, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/uploading-data.html">Uploading Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_599994 = query.getOrDefault("format")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = newJString("sdk"))
  if valid_599994 != nil:
    section.add "format", valid_599994
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Content-Type: JString (required)
  ##               : <p>The format of the batch you are uploading. Amazon CloudSearch supports two document batch formats:</p> <ul> <li>application/json</li> <li>application/xml</li> </ul>
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599995 = header.getOrDefault("X-Amz-Date")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Date", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Security-Token")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Security-Token", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Content-Sha256", valid_599997
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_599998 = header.getOrDefault("Content-Type")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = newJString("application/json"))
  if valid_599998 != nil:
    section.add "Content-Type", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Algorithm")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Algorithm", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Signature")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Signature", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-SignedHeaders", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Credential")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Credential", valid_600002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600004: Call_UploadDocuments_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Posts a batch of documents to a search domain for indexing. A document batch is a collection of add and delete operations that represent the documents you want to add, update, or delete from your domain. Batches can be described in either JSON or XML. Each item that you want Amazon CloudSearch to return as a search result (such as a product) is represented as a document. Every document has a unique ID and one or more fields that contain the data that you want to search and return in results. Individual documents cannot contain more than 1 MB of data. The entire batch cannot exceed 5 MB. To get the best possible upload performance, group add and delete operations in batches that are close the 5 MB limit. Submitting a large volume of single-document batches can overload a domain's document service. </p> <p>The endpoint for submitting <code>UploadDocuments</code> requests is domain-specific. To get the document endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p> <p>For more information about formatting your data for Amazon CloudSearch, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/preparing-data.html">Preparing Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. For more information about uploading data for indexing, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/uploading-data.html">Uploading Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p>
  ## 
  let valid = call_600004.validator(path, query, header, formData, body)
  let scheme = call_600004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600004.url(scheme.get, call_600004.host, call_600004.base,
                         call_600004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600004, url, valid)

proc call*(call_600005: Call_UploadDocuments_599991; body: JsonNode;
          format: string = "sdk"): Recallable =
  ## uploadDocuments
  ## <p>Posts a batch of documents to a search domain for indexing. A document batch is a collection of add and delete operations that represent the documents you want to add, update, or delete from your domain. Batches can be described in either JSON or XML. Each item that you want Amazon CloudSearch to return as a search result (such as a product) is represented as a document. Every document has a unique ID and one or more fields that contain the data that you want to search and return in results. Individual documents cannot contain more than 1 MB of data. The entire batch cannot exceed 5 MB. To get the best possible upload performance, group add and delete operations in batches that are close the 5 MB limit. Submitting a large volume of single-document batches can overload a domain's document service. </p> <p>The endpoint for submitting <code>UploadDocuments</code> requests is domain-specific. To get the document endpoint for your domain, use the Amazon CloudSearch configuration service <code>DescribeDomains</code> action. A domain's endpoints are also displayed on the domain dashboard in the Amazon CloudSearch console. </p> <p>For more information about formatting your data for Amazon CloudSearch, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/preparing-data.html">Preparing Your Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. For more information about uploading data for indexing, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/uploading-data.html">Uploading Data</a> in the <i>Amazon CloudSearch Developer Guide</i>. </p>
  ##   body: JObject (required)
  ##   format: string (required)
  var query_600006 = newJObject()
  var body_600007 = newJObject()
  if body != nil:
    body_600007 = body
  add(query_600006, "format", newJString(format))
  result = call_600005.call(nil, query_600006, nil, nil, body_600007)

var uploadDocuments* = Call_UploadDocuments_599991(name: "uploadDocuments",
    meth: HttpMethod.HttpPost, host: "cloudsearchdomain.amazonaws.com",
    route: "/2013-01-01/documents/batch#format=sdk&Content-Type",
    validator: validate_UploadDocuments_599992, base: "/", url: url_UploadDocuments_599993,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
