
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2013-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the Amazon CloudSearch configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_594045 = ref object of OpenApiRestCall_593437
proc url_PostBuildSuggesters_594047(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBuildSuggesters_594046(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594048 = query.getOrDefault("Action")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_594048 != nil:
    section.add "Action", valid_594048
  var valid_594049 = query.getOrDefault("Version")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594049 != nil:
    section.add "Version", valid_594049
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
  var valid_594050 = header.getOrDefault("X-Amz-Date")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Date", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Security-Token")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Security-Token", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Algorithm")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Algorithm", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Signature")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Signature", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-SignedHeaders", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Credential")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Credential", valid_594056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594057 = formData.getOrDefault("DomainName")
  valid_594057 = validateParameter(valid_594057, JString, required = true,
                                 default = nil)
  if valid_594057 != nil:
    section.add "DomainName", valid_594057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594058: Call_PostBuildSuggesters_594045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594058.validator(path, query, header, formData, body)
  let scheme = call_594058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594058.url(scheme.get, call_594058.host, call_594058.base,
                         call_594058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594058, url, valid)

proc call*(call_594059: Call_PostBuildSuggesters_594045; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594060 = newJObject()
  var formData_594061 = newJObject()
  add(formData_594061, "DomainName", newJString(DomainName))
  add(query_594060, "Action", newJString(Action))
  add(query_594060, "Version", newJString(Version))
  result = call_594059.call(nil, query_594060, nil, formData_594061, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_594045(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_594046, base: "/",
    url: url_PostBuildSuggesters_594047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_593774 = ref object of OpenApiRestCall_593437
proc url_GetBuildSuggesters_593776(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuildSuggesters_593775(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593901 = query.getOrDefault("Action")
  valid_593901 = validateParameter(valid_593901, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_593901 != nil:
    section.add "Action", valid_593901
  var valid_593902 = query.getOrDefault("DomainName")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "DomainName", valid_593902
  var valid_593903 = query.getOrDefault("Version")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593903 != nil:
    section.add "Version", valid_593903
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
  var valid_593904 = header.getOrDefault("X-Amz-Date")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Date", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Security-Token")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Security-Token", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Content-Sha256", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Algorithm")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Algorithm", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Signature")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Signature", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-SignedHeaders", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Credential")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Credential", valid_593910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593933: Call_GetBuildSuggesters_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_GetBuildSuggesters_593774; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594005 = newJObject()
  add(query_594005, "Action", newJString(Action))
  add(query_594005, "DomainName", newJString(DomainName))
  add(query_594005, "Version", newJString(Version))
  result = call_594004.call(nil, query_594005, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_593774(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_593775, base: "/",
    url: url_GetBuildSuggesters_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_594078 = ref object of OpenApiRestCall_593437
proc url_PostCreateDomain_594080(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_594079(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594081 = query.getOrDefault("Action")
  valid_594081 = validateParameter(valid_594081, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_594081 != nil:
    section.add "Action", valid_594081
  var valid_594082 = query.getOrDefault("Version")
  valid_594082 = validateParameter(valid_594082, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594082 != nil:
    section.add "Version", valid_594082
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
  var valid_594083 = header.getOrDefault("X-Amz-Date")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Date", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Security-Token")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Security-Token", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Content-Sha256", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Algorithm")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Algorithm", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Signature")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Signature", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-SignedHeaders", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Credential")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Credential", valid_594089
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594090 = formData.getOrDefault("DomainName")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = nil)
  if valid_594090 != nil:
    section.add "DomainName", valid_594090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594091: Call_PostCreateDomain_594078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594091.validator(path, query, header, formData, body)
  let scheme = call_594091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594091.url(scheme.get, call_594091.host, call_594091.base,
                         call_594091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594091, url, valid)

proc call*(call_594092: Call_PostCreateDomain_594078; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594093 = newJObject()
  var formData_594094 = newJObject()
  add(formData_594094, "DomainName", newJString(DomainName))
  add(query_594093, "Action", newJString(Action))
  add(query_594093, "Version", newJString(Version))
  result = call_594092.call(nil, query_594093, nil, formData_594094, nil)

var postCreateDomain* = Call_PostCreateDomain_594078(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_594079,
    base: "/", url: url_PostCreateDomain_594080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_594062 = ref object of OpenApiRestCall_593437
proc url_GetCreateDomain_594064(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_594063(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594065 = query.getOrDefault("Action")
  valid_594065 = validateParameter(valid_594065, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_594065 != nil:
    section.add "Action", valid_594065
  var valid_594066 = query.getOrDefault("DomainName")
  valid_594066 = validateParameter(valid_594066, JString, required = true,
                                 default = nil)
  if valid_594066 != nil:
    section.add "DomainName", valid_594066
  var valid_594067 = query.getOrDefault("Version")
  valid_594067 = validateParameter(valid_594067, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594067 != nil:
    section.add "Version", valid_594067
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
  var valid_594068 = header.getOrDefault("X-Amz-Date")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Date", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Security-Token")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Security-Token", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Content-Sha256", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Algorithm")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Algorithm", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Signature")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Signature", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-SignedHeaders", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Credential")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Credential", valid_594074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594075: Call_GetCreateDomain_594062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594075.validator(path, query, header, formData, body)
  let scheme = call_594075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594075.url(scheme.get, call_594075.host, call_594075.base,
                         call_594075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594075, url, valid)

proc call*(call_594076: Call_GetCreateDomain_594062; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594077 = newJObject()
  add(query_594077, "Action", newJString(Action))
  add(query_594077, "DomainName", newJString(DomainName))
  add(query_594077, "Version", newJString(Version))
  result = call_594076.call(nil, query_594077, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_594062(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_594063,
    base: "/", url: url_GetCreateDomain_594064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_594114 = ref object of OpenApiRestCall_593437
proc url_PostDefineAnalysisScheme_594116(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineAnalysisScheme_594115(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594117 = query.getOrDefault("Action")
  valid_594117 = validateParameter(valid_594117, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_594117 != nil:
    section.add "Action", valid_594117
  var valid_594118 = query.getOrDefault("Version")
  valid_594118 = validateParameter(valid_594118, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594118 != nil:
    section.add "Version", valid_594118
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
  var valid_594119 = header.getOrDefault("X-Amz-Date")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Date", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Security-Token")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Security-Token", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Algorithm")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Algorithm", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Signature")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Signature", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-SignedHeaders", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Credential")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Credential", valid_594125
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_594126 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_594126
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594127 = formData.getOrDefault("DomainName")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = nil)
  if valid_594127 != nil:
    section.add "DomainName", valid_594127
  var valid_594128 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_594128
  var valid_594129 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_594129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_PostDefineAnalysisScheme_594114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_PostDefineAnalysisScheme_594114; DomainName: string;
          AnalysisSchemeAnalysisOptions: string = "";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_594132 = newJObject()
  var formData_594133 = newJObject()
  add(formData_594133, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_594133, "DomainName", newJString(DomainName))
  add(formData_594133, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_594132, "Action", newJString(Action))
  add(formData_594133, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_594132, "Version", newJString(Version))
  result = call_594131.call(nil, query_594132, nil, formData_594133, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_594114(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_594115, base: "/",
    url: url_PostDefineAnalysisScheme_594116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_594095 = ref object of OpenApiRestCall_593437
proc url_GetDefineAnalysisScheme_594097(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineAnalysisScheme_594096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594098 = query.getOrDefault("Action")
  valid_594098 = validateParameter(valid_594098, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_594098 != nil:
    section.add "Action", valid_594098
  var valid_594099 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_594099
  var valid_594100 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_594100
  var valid_594101 = query.getOrDefault("DomainName")
  valid_594101 = validateParameter(valid_594101, JString, required = true,
                                 default = nil)
  if valid_594101 != nil:
    section.add "DomainName", valid_594101
  var valid_594102 = query.getOrDefault("Version")
  valid_594102 = validateParameter(valid_594102, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594102 != nil:
    section.add "Version", valid_594102
  var valid_594103 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_594103
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
  var valid_594104 = header.getOrDefault("X-Amz-Date")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Date", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Security-Token")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Security-Token", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Content-Sha256", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Algorithm")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Algorithm", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Signature")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Signature", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-SignedHeaders", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Credential")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Credential", valid_594110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594111: Call_GetDefineAnalysisScheme_594095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594111.validator(path, query, header, formData, body)
  let scheme = call_594111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594111.url(scheme.get, call_594111.host, call_594111.base,
                         call_594111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594111, url, valid)

proc call*(call_594112: Call_GetDefineAnalysisScheme_594095; DomainName: string;
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"; AnalysisSchemeAnalysisOptions: string = ""): Recallable =
  ## getDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  var query_594113 = newJObject()
  add(query_594113, "Action", newJString(Action))
  add(query_594113, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_594113, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_594113, "DomainName", newJString(DomainName))
  add(query_594113, "Version", newJString(Version))
  add(query_594113, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_594112.call(nil, query_594113, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_594095(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_594096, base: "/",
    url: url_GetDefineAnalysisScheme_594097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_594152 = ref object of OpenApiRestCall_593437
proc url_PostDefineExpression_594154(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineExpression_594153(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594155 = query.getOrDefault("Action")
  valid_594155 = validateParameter(valid_594155, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_594155 != nil:
    section.add "Action", valid_594155
  var valid_594156 = query.getOrDefault("Version")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594156 != nil:
    section.add "Version", valid_594156
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
  var valid_594157 = header.getOrDefault("X-Amz-Date")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Date", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Security-Token")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Security-Token", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Content-Sha256", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Algorithm")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Algorithm", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Signature")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Signature", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-SignedHeaders", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Credential")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Credential", valid_594163
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594164 = formData.getOrDefault("DomainName")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = nil)
  if valid_594164 != nil:
    section.add "DomainName", valid_594164
  var valid_594165 = formData.getOrDefault("Expression.ExpressionName")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "Expression.ExpressionName", valid_594165
  var valid_594166 = formData.getOrDefault("Expression.ExpressionValue")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "Expression.ExpressionValue", valid_594166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_PostDefineExpression_594152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_PostDefineExpression_594152; DomainName: string;
          ExpressionExpressionName: string = "";
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594169 = newJObject()
  var formData_594170 = newJObject()
  add(formData_594170, "DomainName", newJString(DomainName))
  add(formData_594170, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_594170, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_594169, "Action", newJString(Action))
  add(query_594169, "Version", newJString(Version))
  result = call_594168.call(nil, query_594169, nil, formData_594170, nil)

var postDefineExpression* = Call_PostDefineExpression_594152(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_594153, base: "/",
    url: url_PostDefineExpression_594154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_594134 = ref object of OpenApiRestCall_593437
proc url_GetDefineExpression_594136(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineExpression_594135(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594137 = query.getOrDefault("Action")
  valid_594137 = validateParameter(valid_594137, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_594137 != nil:
    section.add "Action", valid_594137
  var valid_594138 = query.getOrDefault("Expression.ExpressionValue")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "Expression.ExpressionValue", valid_594138
  var valid_594139 = query.getOrDefault("Expression.ExpressionName")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "Expression.ExpressionName", valid_594139
  var valid_594140 = query.getOrDefault("DomainName")
  valid_594140 = validateParameter(valid_594140, JString, required = true,
                                 default = nil)
  if valid_594140 != nil:
    section.add "DomainName", valid_594140
  var valid_594141 = query.getOrDefault("Version")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594141 != nil:
    section.add "Version", valid_594141
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
  var valid_594142 = header.getOrDefault("X-Amz-Date")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Date", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Security-Token")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Security-Token", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Content-Sha256", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Algorithm")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Algorithm", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Signature")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Signature", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-SignedHeaders", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Credential")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Credential", valid_594148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594149: Call_GetDefineExpression_594134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594149.validator(path, query, header, formData, body)
  let scheme = call_594149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594149.url(scheme.get, call_594149.host, call_594149.base,
                         call_594149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594149, url, valid)

proc call*(call_594150: Call_GetDefineExpression_594134; DomainName: string;
          Action: string = "DefineExpression";
          ExpressionExpressionValue: string = "";
          ExpressionExpressionName: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594151 = newJObject()
  add(query_594151, "Action", newJString(Action))
  add(query_594151, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_594151, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_594151, "DomainName", newJString(DomainName))
  add(query_594151, "Version", newJString(Version))
  result = call_594150.call(nil, query_594151, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_594134(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_594135, base: "/",
    url: url_GetDefineExpression_594136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_594200 = ref object of OpenApiRestCall_593437
proc url_PostDefineIndexField_594202(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_594201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594203 = query.getOrDefault("Action")
  valid_594203 = validateParameter(valid_594203, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_594203 != nil:
    section.add "Action", valid_594203
  var valid_594204 = query.getOrDefault("Version")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594204 != nil:
    section.add "Version", valid_594204
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
  var valid_594205 = header.getOrDefault("X-Amz-Date")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Date", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Security-Token")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Security-Token", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Algorithm")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Algorithm", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-SignedHeaders", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Credential")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Credential", valid_594211
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_594212 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "IndexField.TextArrayOptions", valid_594212
  var valid_594213 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "IndexField.DateArrayOptions", valid_594213
  var valid_594214 = formData.getOrDefault("IndexField.TextOptions")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "IndexField.TextOptions", valid_594214
  var valid_594215 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "IndexField.DoubleOptions", valid_594215
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594216 = formData.getOrDefault("DomainName")
  valid_594216 = validateParameter(valid_594216, JString, required = true,
                                 default = nil)
  if valid_594216 != nil:
    section.add "DomainName", valid_594216
  var valid_594217 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "IndexField.LiteralOptions", valid_594217
  var valid_594218 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_594218
  var valid_594219 = formData.getOrDefault("IndexField.DateOptions")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "IndexField.DateOptions", valid_594219
  var valid_594220 = formData.getOrDefault("IndexField.IntOptions")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "IndexField.IntOptions", valid_594220
  var valid_594221 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "IndexField.LatLonOptions", valid_594221
  var valid_594222 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "IndexField.IndexFieldType", valid_594222
  var valid_594223 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_594223
  var valid_594224 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "IndexField.IndexFieldName", valid_594224
  var valid_594225 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "IndexField.IntArrayOptions", valid_594225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594226: Call_PostDefineIndexField_594200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594226.validator(path, query, header, formData, body)
  let scheme = call_594226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594226.url(scheme.get, call_594226.host, call_594226.base,
                         call_594226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594226, url, valid)

proc call*(call_594227: Call_PostDefineIndexField_594200; DomainName: string;
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldTextOptions: string = ""; IndexFieldDoubleOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldDateOptions: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldDoubleArrayOptions: string = "";
          IndexFieldIndexFieldName: string = ""; Version: string = "2013-01-01";
          IndexFieldIntArrayOptions: string = ""): Recallable =
  ## postDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   Version: string (required)
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_594228 = newJObject()
  var formData_594229 = newJObject()
  add(formData_594229, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_594229, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_594229, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_594229, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_594229, "DomainName", newJString(DomainName))
  add(formData_594229, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_594229, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_594229, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_594229, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_594229, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_594229, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_594228, "Action", newJString(Action))
  add(formData_594229, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_594229, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_594228, "Version", newJString(Version))
  add(formData_594229, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_594227.call(nil, query_594228, nil, formData_594229, nil)

var postDefineIndexField* = Call_PostDefineIndexField_594200(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_594201, base: "/",
    url: url_PostDefineIndexField_594202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_594171 = ref object of OpenApiRestCall_593437
proc url_GetDefineIndexField_594173(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_594172(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: JString (required)
  section = newJObject()
  var valid_594174 = query.getOrDefault("IndexField.TextOptions")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "IndexField.TextOptions", valid_594174
  var valid_594175 = query.getOrDefault("IndexField.DateOptions")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "IndexField.DateOptions", valid_594175
  var valid_594176 = query.getOrDefault("IndexField.LiteralOptions")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "IndexField.LiteralOptions", valid_594176
  var valid_594177 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_594177
  var valid_594178 = query.getOrDefault("IndexField.IndexFieldType")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "IndexField.IndexFieldType", valid_594178
  var valid_594179 = query.getOrDefault("IndexField.IntOptions")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "IndexField.IntOptions", valid_594179
  var valid_594180 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "IndexField.DateArrayOptions", valid_594180
  var valid_594181 = query.getOrDefault("IndexField.DoubleOptions")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "IndexField.DoubleOptions", valid_594181
  var valid_594182 = query.getOrDefault("IndexField.IndexFieldName")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "IndexField.IndexFieldName", valid_594182
  var valid_594183 = query.getOrDefault("IndexField.LatLonOptions")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "IndexField.LatLonOptions", valid_594183
  var valid_594184 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "IndexField.IntArrayOptions", valid_594184
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594185 = query.getOrDefault("Action")
  valid_594185 = validateParameter(valid_594185, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_594185 != nil:
    section.add "Action", valid_594185
  var valid_594186 = query.getOrDefault("DomainName")
  valid_594186 = validateParameter(valid_594186, JString, required = true,
                                 default = nil)
  if valid_594186 != nil:
    section.add "DomainName", valid_594186
  var valid_594187 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "IndexField.TextArrayOptions", valid_594187
  var valid_594188 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_594188
  var valid_594189 = query.getOrDefault("Version")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594189 != nil:
    section.add "Version", valid_594189
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
  var valid_594190 = header.getOrDefault("X-Amz-Date")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Date", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Security-Token")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Security-Token", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Content-Sha256", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Algorithm")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Algorithm", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Signature")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Signature", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-SignedHeaders", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Credential")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Credential", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594197: Call_GetDefineIndexField_594171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594197.validator(path, query, header, formData, body)
  let scheme = call_594197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594197.url(scheme.get, call_594197.host, call_594197.base,
                         call_594197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594197, url, valid)

proc call*(call_594198: Call_GetDefineIndexField_594171; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldDateOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldIndexFieldType: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldIndexFieldName: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDoubleArrayOptions: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  var query_594199 = newJObject()
  add(query_594199, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_594199, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_594199, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_594199, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_594199, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_594199, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_594199, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_594199, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_594199, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_594199, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_594199, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_594199, "Action", newJString(Action))
  add(query_594199, "DomainName", newJString(DomainName))
  add(query_594199, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_594199, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_594199, "Version", newJString(Version))
  result = call_594198.call(nil, query_594199, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_594171(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_594172, base: "/",
    url: url_GetDefineIndexField_594173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_594248 = ref object of OpenApiRestCall_593437
proc url_PostDefineSuggester_594250(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineSuggester_594249(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594251 = query.getOrDefault("Action")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_594251 != nil:
    section.add "Action", valid_594251
  var valid_594252 = query.getOrDefault("Version")
  valid_594252 = validateParameter(valid_594252, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594252 != nil:
    section.add "Version", valid_594252
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
  var valid_594253 = header.getOrDefault("X-Amz-Date")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Date", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Security-Token")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Security-Token", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Content-Sha256", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Algorithm")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Algorithm", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Signature")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Signature", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-SignedHeaders", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Credential")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Credential", valid_594259
  result.add "header", section
  ## parameters in `formData` object:
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  section = newJObject()
  var valid_594260 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_594260
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594261 = formData.getOrDefault("DomainName")
  valid_594261 = validateParameter(valid_594261, JString, required = true,
                                 default = nil)
  if valid_594261 != nil:
    section.add "DomainName", valid_594261
  var valid_594262 = formData.getOrDefault("Suggester.SuggesterName")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "Suggester.SuggesterName", valid_594262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_PostDefineSuggester_594248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_PostDefineSuggester_594248; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; Version: string = "2013-01-01";
          SuggesterSuggesterName: string = ""): Recallable =
  ## postDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  var query_594265 = newJObject()
  var formData_594266 = newJObject()
  add(formData_594266, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_594266, "DomainName", newJString(DomainName))
  add(query_594265, "Action", newJString(Action))
  add(query_594265, "Version", newJString(Version))
  add(formData_594266, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_594264.call(nil, query_594265, nil, formData_594266, nil)

var postDefineSuggester* = Call_PostDefineSuggester_594248(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_594249, base: "/",
    url: url_PostDefineSuggester_594250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_594230 = ref object of OpenApiRestCall_593437
proc url_GetDefineSuggester_594232(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineSuggester_594231(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: JString (required)
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594233 = query.getOrDefault("Suggester.SuggesterName")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "Suggester.SuggesterName", valid_594233
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594234 = query.getOrDefault("Action")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_594234 != nil:
    section.add "Action", valid_594234
  var valid_594235 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_594235
  var valid_594236 = query.getOrDefault("DomainName")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = nil)
  if valid_594236 != nil:
    section.add "DomainName", valid_594236
  var valid_594237 = query.getOrDefault("Version")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594237 != nil:
    section.add "Version", valid_594237
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
  var valid_594238 = header.getOrDefault("X-Amz-Date")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Date", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Security-Token")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Security-Token", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Content-Sha256", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Algorithm")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Algorithm", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Signature")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Signature", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-SignedHeaders", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Credential")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Credential", valid_594244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594245: Call_GetDefineSuggester_594230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594245.validator(path, query, header, formData, body)
  let scheme = call_594245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594245.url(scheme.get, call_594245.host, call_594245.base,
                         call_594245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594245, url, valid)

proc call*(call_594246: Call_GetDefineSuggester_594230; DomainName: string;
          SuggesterSuggesterName: string = ""; Action: string = "DefineSuggester";
          SuggesterDocumentSuggesterOptions: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594247 = newJObject()
  add(query_594247, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_594247, "Action", newJString(Action))
  add(query_594247, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_594247, "DomainName", newJString(DomainName))
  add(query_594247, "Version", newJString(Version))
  result = call_594246.call(nil, query_594247, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_594230(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_594231, base: "/",
    url: url_GetDefineSuggester_594232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_594284 = ref object of OpenApiRestCall_593437
proc url_PostDeleteAnalysisScheme_594286(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnalysisScheme_594285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594287 = query.getOrDefault("Action")
  valid_594287 = validateParameter(valid_594287, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_594287 != nil:
    section.add "Action", valid_594287
  var valid_594288 = query.getOrDefault("Version")
  valid_594288 = validateParameter(valid_594288, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594288 != nil:
    section.add "Version", valid_594288
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
  var valid_594289 = header.getOrDefault("X-Amz-Date")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Date", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Security-Token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Security-Token", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Content-Sha256", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Algorithm")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Algorithm", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Signature")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Signature", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-SignedHeaders", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Credential")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Credential", valid_594295
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594296 = formData.getOrDefault("DomainName")
  valid_594296 = validateParameter(valid_594296, JString, required = true,
                                 default = nil)
  if valid_594296 != nil:
    section.add "DomainName", valid_594296
  var valid_594297 = formData.getOrDefault("AnalysisSchemeName")
  valid_594297 = validateParameter(valid_594297, JString, required = true,
                                 default = nil)
  if valid_594297 != nil:
    section.add "AnalysisSchemeName", valid_594297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594298: Call_PostDeleteAnalysisScheme_594284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594298.validator(path, query, header, formData, body)
  let scheme = call_594298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594298.url(scheme.get, call_594298.host, call_594298.base,
                         call_594298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594298, url, valid)

proc call*(call_594299: Call_PostDeleteAnalysisScheme_594284; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594300 = newJObject()
  var formData_594301 = newJObject()
  add(formData_594301, "DomainName", newJString(DomainName))
  add(formData_594301, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_594300, "Action", newJString(Action))
  add(query_594300, "Version", newJString(Version))
  result = call_594299.call(nil, query_594300, nil, formData_594301, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_594284(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_594285, base: "/",
    url: url_PostDeleteAnalysisScheme_594286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_594267 = ref object of OpenApiRestCall_593437
proc url_GetDeleteAnalysisScheme_594269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnalysisScheme_594268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594270 = query.getOrDefault("Action")
  valid_594270 = validateParameter(valid_594270, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_594270 != nil:
    section.add "Action", valid_594270
  var valid_594271 = query.getOrDefault("DomainName")
  valid_594271 = validateParameter(valid_594271, JString, required = true,
                                 default = nil)
  if valid_594271 != nil:
    section.add "DomainName", valid_594271
  var valid_594272 = query.getOrDefault("AnalysisSchemeName")
  valid_594272 = validateParameter(valid_594272, JString, required = true,
                                 default = nil)
  if valid_594272 != nil:
    section.add "AnalysisSchemeName", valid_594272
  var valid_594273 = query.getOrDefault("Version")
  valid_594273 = validateParameter(valid_594273, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594273 != nil:
    section.add "Version", valid_594273
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
  var valid_594274 = header.getOrDefault("X-Amz-Date")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Date", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Security-Token")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Security-Token", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Content-Sha256", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Algorithm")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Algorithm", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Signature")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Signature", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-SignedHeaders", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Credential")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Credential", valid_594280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594281: Call_GetDeleteAnalysisScheme_594267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594281.validator(path, query, header, formData, body)
  let scheme = call_594281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594281.url(scheme.get, call_594281.host, call_594281.base,
                         call_594281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594281, url, valid)

proc call*(call_594282: Call_GetDeleteAnalysisScheme_594267; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_594283 = newJObject()
  add(query_594283, "Action", newJString(Action))
  add(query_594283, "DomainName", newJString(DomainName))
  add(query_594283, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_594283, "Version", newJString(Version))
  result = call_594282.call(nil, query_594283, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_594267(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_594268, base: "/",
    url: url_GetDeleteAnalysisScheme_594269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_594318 = ref object of OpenApiRestCall_593437
proc url_PostDeleteDomain_594320(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_594319(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594321 = query.getOrDefault("Action")
  valid_594321 = validateParameter(valid_594321, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_594321 != nil:
    section.add "Action", valid_594321
  var valid_594322 = query.getOrDefault("Version")
  valid_594322 = validateParameter(valid_594322, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594322 != nil:
    section.add "Version", valid_594322
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
  var valid_594323 = header.getOrDefault("X-Amz-Date")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Date", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Security-Token")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Security-Token", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Content-Sha256", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Algorithm")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Algorithm", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Signature")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Signature", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-SignedHeaders", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Credential")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Credential", valid_594329
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594330 = formData.getOrDefault("DomainName")
  valid_594330 = validateParameter(valid_594330, JString, required = true,
                                 default = nil)
  if valid_594330 != nil:
    section.add "DomainName", valid_594330
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594331: Call_PostDeleteDomain_594318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594331.validator(path, query, header, formData, body)
  let scheme = call_594331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594331.url(scheme.get, call_594331.host, call_594331.base,
                         call_594331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594331, url, valid)

proc call*(call_594332: Call_PostDeleteDomain_594318; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594333 = newJObject()
  var formData_594334 = newJObject()
  add(formData_594334, "DomainName", newJString(DomainName))
  add(query_594333, "Action", newJString(Action))
  add(query_594333, "Version", newJString(Version))
  result = call_594332.call(nil, query_594333, nil, formData_594334, nil)

var postDeleteDomain* = Call_PostDeleteDomain_594318(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_594319,
    base: "/", url: url_PostDeleteDomain_594320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_594302 = ref object of OpenApiRestCall_593437
proc url_GetDeleteDomain_594304(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_594303(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594305 = query.getOrDefault("Action")
  valid_594305 = validateParameter(valid_594305, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_594305 != nil:
    section.add "Action", valid_594305
  var valid_594306 = query.getOrDefault("DomainName")
  valid_594306 = validateParameter(valid_594306, JString, required = true,
                                 default = nil)
  if valid_594306 != nil:
    section.add "DomainName", valid_594306
  var valid_594307 = query.getOrDefault("Version")
  valid_594307 = validateParameter(valid_594307, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594307 != nil:
    section.add "Version", valid_594307
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
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Content-Sha256", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-SignedHeaders", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Credential")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Credential", valid_594314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594315: Call_GetDeleteDomain_594302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594315.validator(path, query, header, formData, body)
  let scheme = call_594315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594315.url(scheme.get, call_594315.host, call_594315.base,
                         call_594315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594315, url, valid)

proc call*(call_594316: Call_GetDeleteDomain_594302; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594317 = newJObject()
  add(query_594317, "Action", newJString(Action))
  add(query_594317, "DomainName", newJString(DomainName))
  add(query_594317, "Version", newJString(Version))
  result = call_594316.call(nil, query_594317, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_594302(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_594303,
    base: "/", url: url_GetDeleteDomain_594304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_594352 = ref object of OpenApiRestCall_593437
proc url_PostDeleteExpression_594354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteExpression_594353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594355 = query.getOrDefault("Action")
  valid_594355 = validateParameter(valid_594355, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_594355 != nil:
    section.add "Action", valid_594355
  var valid_594356 = query.getOrDefault("Version")
  valid_594356 = validateParameter(valid_594356, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594356 != nil:
    section.add "Version", valid_594356
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
  var valid_594357 = header.getOrDefault("X-Amz-Date")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Date", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Security-Token")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Security-Token", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Content-Sha256", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Algorithm")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Algorithm", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Signature")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Signature", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-SignedHeaders", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Credential")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Credential", valid_594363
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_594364 = formData.getOrDefault("ExpressionName")
  valid_594364 = validateParameter(valid_594364, JString, required = true,
                                 default = nil)
  if valid_594364 != nil:
    section.add "ExpressionName", valid_594364
  var valid_594365 = formData.getOrDefault("DomainName")
  valid_594365 = validateParameter(valid_594365, JString, required = true,
                                 default = nil)
  if valid_594365 != nil:
    section.add "DomainName", valid_594365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594366: Call_PostDeleteExpression_594352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594366.validator(path, query, header, formData, body)
  let scheme = call_594366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594366.url(scheme.get, call_594366.host, call_594366.base,
                         call_594366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594366, url, valid)

proc call*(call_594367: Call_PostDeleteExpression_594352; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594368 = newJObject()
  var formData_594369 = newJObject()
  add(formData_594369, "ExpressionName", newJString(ExpressionName))
  add(formData_594369, "DomainName", newJString(DomainName))
  add(query_594368, "Action", newJString(Action))
  add(query_594368, "Version", newJString(Version))
  result = call_594367.call(nil, query_594368, nil, formData_594369, nil)

var postDeleteExpression* = Call_PostDeleteExpression_594352(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_594353, base: "/",
    url: url_PostDeleteExpression_594354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_594335 = ref object of OpenApiRestCall_593437
proc url_GetDeleteExpression_594337(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteExpression_594336(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594338 = query.getOrDefault("Action")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_594338 != nil:
    section.add "Action", valid_594338
  var valid_594339 = query.getOrDefault("ExpressionName")
  valid_594339 = validateParameter(valid_594339, JString, required = true,
                                 default = nil)
  if valid_594339 != nil:
    section.add "ExpressionName", valid_594339
  var valid_594340 = query.getOrDefault("DomainName")
  valid_594340 = validateParameter(valid_594340, JString, required = true,
                                 default = nil)
  if valid_594340 != nil:
    section.add "DomainName", valid_594340
  var valid_594341 = query.getOrDefault("Version")
  valid_594341 = validateParameter(valid_594341, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594341 != nil:
    section.add "Version", valid_594341
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
  var valid_594342 = header.getOrDefault("X-Amz-Date")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Date", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Security-Token")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Security-Token", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Content-Sha256", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Algorithm")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Algorithm", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Signature")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Signature", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-SignedHeaders", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Credential")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Credential", valid_594348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594349: Call_GetDeleteExpression_594335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594349.validator(path, query, header, formData, body)
  let scheme = call_594349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594349.url(scheme.get, call_594349.host, call_594349.base,
                         call_594349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594349, url, valid)

proc call*(call_594350: Call_GetDeleteExpression_594335; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594351 = newJObject()
  add(query_594351, "Action", newJString(Action))
  add(query_594351, "ExpressionName", newJString(ExpressionName))
  add(query_594351, "DomainName", newJString(DomainName))
  add(query_594351, "Version", newJString(Version))
  result = call_594350.call(nil, query_594351, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_594335(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_594336, base: "/",
    url: url_GetDeleteExpression_594337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_594387 = ref object of OpenApiRestCall_593437
proc url_PostDeleteIndexField_594389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_594388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594390 = query.getOrDefault("Action")
  valid_594390 = validateParameter(valid_594390, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_594390 != nil:
    section.add "Action", valid_594390
  var valid_594391 = query.getOrDefault("Version")
  valid_594391 = validateParameter(valid_594391, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594391 != nil:
    section.add "Version", valid_594391
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
  var valid_594392 = header.getOrDefault("X-Amz-Date")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Date", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594399 = formData.getOrDefault("DomainName")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = nil)
  if valid_594399 != nil:
    section.add "DomainName", valid_594399
  var valid_594400 = formData.getOrDefault("IndexFieldName")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = nil)
  if valid_594400 != nil:
    section.add "IndexFieldName", valid_594400
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_PostDeleteIndexField_594387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_PostDeleteIndexField_594387; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594403 = newJObject()
  var formData_594404 = newJObject()
  add(formData_594404, "DomainName", newJString(DomainName))
  add(formData_594404, "IndexFieldName", newJString(IndexFieldName))
  add(query_594403, "Action", newJString(Action))
  add(query_594403, "Version", newJString(Version))
  result = call_594402.call(nil, query_594403, nil, formData_594404, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_594387(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_594388, base: "/",
    url: url_PostDeleteIndexField_594389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_594370 = ref object of OpenApiRestCall_593437
proc url_GetDeleteIndexField_594372(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_594371(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_594373 = query.getOrDefault("IndexFieldName")
  valid_594373 = validateParameter(valid_594373, JString, required = true,
                                 default = nil)
  if valid_594373 != nil:
    section.add "IndexFieldName", valid_594373
  var valid_594374 = query.getOrDefault("Action")
  valid_594374 = validateParameter(valid_594374, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_594374 != nil:
    section.add "Action", valid_594374
  var valid_594375 = query.getOrDefault("DomainName")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = nil)
  if valid_594375 != nil:
    section.add "DomainName", valid_594375
  var valid_594376 = query.getOrDefault("Version")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594376 != nil:
    section.add "Version", valid_594376
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
  var valid_594377 = header.getOrDefault("X-Amz-Date")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Date", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Security-Token")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Security-Token", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594384: Call_GetDeleteIndexField_594370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594384.validator(path, query, header, formData, body)
  let scheme = call_594384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594384.url(scheme.get, call_594384.host, call_594384.base,
                         call_594384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594384, url, valid)

proc call*(call_594385: Call_GetDeleteIndexField_594370; IndexFieldName: string;
          DomainName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594386 = newJObject()
  add(query_594386, "IndexFieldName", newJString(IndexFieldName))
  add(query_594386, "Action", newJString(Action))
  add(query_594386, "DomainName", newJString(DomainName))
  add(query_594386, "Version", newJString(Version))
  result = call_594385.call(nil, query_594386, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_594370(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_594371, base: "/",
    url: url_GetDeleteIndexField_594372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_594422 = ref object of OpenApiRestCall_593437
proc url_PostDeleteSuggester_594424(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteSuggester_594423(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594425 = query.getOrDefault("Action")
  valid_594425 = validateParameter(valid_594425, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_594425 != nil:
    section.add "Action", valid_594425
  var valid_594426 = query.getOrDefault("Version")
  valid_594426 = validateParameter(valid_594426, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594426 != nil:
    section.add "Version", valid_594426
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
  var valid_594427 = header.getOrDefault("X-Amz-Date")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Date", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Security-Token")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Security-Token", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Content-Sha256", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Algorithm")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Algorithm", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Signature")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Signature", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-SignedHeaders", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Credential")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Credential", valid_594433
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594434 = formData.getOrDefault("DomainName")
  valid_594434 = validateParameter(valid_594434, JString, required = true,
                                 default = nil)
  if valid_594434 != nil:
    section.add "DomainName", valid_594434
  var valid_594435 = formData.getOrDefault("SuggesterName")
  valid_594435 = validateParameter(valid_594435, JString, required = true,
                                 default = nil)
  if valid_594435 != nil:
    section.add "SuggesterName", valid_594435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594436: Call_PostDeleteSuggester_594422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594436.validator(path, query, header, formData, body)
  let scheme = call_594436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594436.url(scheme.get, call_594436.host, call_594436.base,
                         call_594436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594436, url, valid)

proc call*(call_594437: Call_PostDeleteSuggester_594422; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_594438 = newJObject()
  var formData_594439 = newJObject()
  add(formData_594439, "DomainName", newJString(DomainName))
  add(query_594438, "Action", newJString(Action))
  add(formData_594439, "SuggesterName", newJString(SuggesterName))
  add(query_594438, "Version", newJString(Version))
  result = call_594437.call(nil, query_594438, nil, formData_594439, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_594422(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_594423, base: "/",
    url: url_PostDeleteSuggester_594424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_594405 = ref object of OpenApiRestCall_593437
proc url_GetDeleteSuggester_594407(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteSuggester_594406(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594408 = query.getOrDefault("Action")
  valid_594408 = validateParameter(valid_594408, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_594408 != nil:
    section.add "Action", valid_594408
  var valid_594409 = query.getOrDefault("SuggesterName")
  valid_594409 = validateParameter(valid_594409, JString, required = true,
                                 default = nil)
  if valid_594409 != nil:
    section.add "SuggesterName", valid_594409
  var valid_594410 = query.getOrDefault("DomainName")
  valid_594410 = validateParameter(valid_594410, JString, required = true,
                                 default = nil)
  if valid_594410 != nil:
    section.add "DomainName", valid_594410
  var valid_594411 = query.getOrDefault("Version")
  valid_594411 = validateParameter(valid_594411, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594411 != nil:
    section.add "Version", valid_594411
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
  var valid_594412 = header.getOrDefault("X-Amz-Date")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Date", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Security-Token")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Security-Token", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Content-Sha256", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Algorithm")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Algorithm", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Signature")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Signature", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-SignedHeaders", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Credential")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Credential", valid_594418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594419: Call_GetDeleteSuggester_594405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594419.validator(path, query, header, formData, body)
  let scheme = call_594419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594419.url(scheme.get, call_594419.host, call_594419.base,
                         call_594419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594419, url, valid)

proc call*(call_594420: Call_GetDeleteSuggester_594405; SuggesterName: string;
          DomainName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594421 = newJObject()
  add(query_594421, "Action", newJString(Action))
  add(query_594421, "SuggesterName", newJString(SuggesterName))
  add(query_594421, "DomainName", newJString(DomainName))
  add(query_594421, "Version", newJString(Version))
  result = call_594420.call(nil, query_594421, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_594405(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_594406, base: "/",
    url: url_GetDeleteSuggester_594407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_594458 = ref object of OpenApiRestCall_593437
proc url_PostDescribeAnalysisSchemes_594460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnalysisSchemes_594459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594461 = query.getOrDefault("Action")
  valid_594461 = validateParameter(valid_594461, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_594461 != nil:
    section.add "Action", valid_594461
  var valid_594462 = query.getOrDefault("Version")
  valid_594462 = validateParameter(valid_594462, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594462 != nil:
    section.add "Version", valid_594462
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
  var valid_594463 = header.getOrDefault("X-Amz-Date")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Date", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Security-Token")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Security-Token", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Content-Sha256", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Algorithm")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Algorithm", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Signature")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Signature", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-SignedHeaders", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Credential")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Credential", valid_594469
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594470 = formData.getOrDefault("DomainName")
  valid_594470 = validateParameter(valid_594470, JString, required = true,
                                 default = nil)
  if valid_594470 != nil:
    section.add "DomainName", valid_594470
  var valid_594471 = formData.getOrDefault("Deployed")
  valid_594471 = validateParameter(valid_594471, JBool, required = false, default = nil)
  if valid_594471 != nil:
    section.add "Deployed", valid_594471
  var valid_594472 = formData.getOrDefault("AnalysisSchemeNames")
  valid_594472 = validateParameter(valid_594472, JArray, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "AnalysisSchemeNames", valid_594472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594473: Call_PostDescribeAnalysisSchemes_594458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594473.validator(path, query, header, formData, body)
  let scheme = call_594473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594473.url(scheme.get, call_594473.host, call_594473.base,
                         call_594473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594473, url, valid)

proc call*(call_594474: Call_PostDescribeAnalysisSchemes_594458;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAnalysisSchemes";
          AnalysisSchemeNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Version: string (required)
  var query_594475 = newJObject()
  var formData_594476 = newJObject()
  add(formData_594476, "DomainName", newJString(DomainName))
  add(formData_594476, "Deployed", newJBool(Deployed))
  add(query_594475, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_594476.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_594475, "Version", newJString(Version))
  result = call_594474.call(nil, query_594475, nil, formData_594476, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_594458(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_594459, base: "/",
    url: url_PostDescribeAnalysisSchemes_594460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_594440 = ref object of OpenApiRestCall_593437
proc url_GetDescribeAnalysisSchemes_594442(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnalysisSchemes_594441(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594443 = query.getOrDefault("Deployed")
  valid_594443 = validateParameter(valid_594443, JBool, required = false, default = nil)
  if valid_594443 != nil:
    section.add "Deployed", valid_594443
  var valid_594444 = query.getOrDefault("AnalysisSchemeNames")
  valid_594444 = validateParameter(valid_594444, JArray, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "AnalysisSchemeNames", valid_594444
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594445 = query.getOrDefault("Action")
  valid_594445 = validateParameter(valid_594445, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_594445 != nil:
    section.add "Action", valid_594445
  var valid_594446 = query.getOrDefault("DomainName")
  valid_594446 = validateParameter(valid_594446, JString, required = true,
                                 default = nil)
  if valid_594446 != nil:
    section.add "DomainName", valid_594446
  var valid_594447 = query.getOrDefault("Version")
  valid_594447 = validateParameter(valid_594447, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594447 != nil:
    section.add "Version", valid_594447
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
  var valid_594448 = header.getOrDefault("X-Amz-Date")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Date", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Security-Token")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Security-Token", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Content-Sha256", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Algorithm")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Algorithm", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Signature")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Signature", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-SignedHeaders", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Credential")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Credential", valid_594454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594455: Call_GetDescribeAnalysisSchemes_594440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594455.validator(path, query, header, formData, body)
  let scheme = call_594455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594455.url(scheme.get, call_594455.host, call_594455.base,
                         call_594455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594455, url, valid)

proc call*(call_594456: Call_GetDescribeAnalysisSchemes_594440; DomainName: string;
          Deployed: bool = false; AnalysisSchemeNames: JsonNode = nil;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594457 = newJObject()
  add(query_594457, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_594457.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_594457, "Action", newJString(Action))
  add(query_594457, "DomainName", newJString(DomainName))
  add(query_594457, "Version", newJString(Version))
  result = call_594456.call(nil, query_594457, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_594440(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_594441, base: "/",
    url: url_GetDescribeAnalysisSchemes_594442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_594494 = ref object of OpenApiRestCall_593437
proc url_PostDescribeAvailabilityOptions_594496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_594495(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594497 = query.getOrDefault("Action")
  valid_594497 = validateParameter(valid_594497, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_594497 != nil:
    section.add "Action", valid_594497
  var valid_594498 = query.getOrDefault("Version")
  valid_594498 = validateParameter(valid_594498, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594498 != nil:
    section.add "Version", valid_594498
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
  var valid_594499 = header.getOrDefault("X-Amz-Date")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Date", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Security-Token")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Security-Token", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Content-Sha256", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Algorithm")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Algorithm", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Signature")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Signature", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-SignedHeaders", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Credential")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Credential", valid_594505
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594506 = formData.getOrDefault("DomainName")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = nil)
  if valid_594506 != nil:
    section.add "DomainName", valid_594506
  var valid_594507 = formData.getOrDefault("Deployed")
  valid_594507 = validateParameter(valid_594507, JBool, required = false, default = nil)
  if valid_594507 != nil:
    section.add "Deployed", valid_594507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594508: Call_PostDescribeAvailabilityOptions_594494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594508.validator(path, query, header, formData, body)
  let scheme = call_594508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594508.url(scheme.get, call_594508.host, call_594508.base,
                         call_594508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594508, url, valid)

proc call*(call_594509: Call_PostDescribeAvailabilityOptions_594494;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594510 = newJObject()
  var formData_594511 = newJObject()
  add(formData_594511, "DomainName", newJString(DomainName))
  add(formData_594511, "Deployed", newJBool(Deployed))
  add(query_594510, "Action", newJString(Action))
  add(query_594510, "Version", newJString(Version))
  result = call_594509.call(nil, query_594510, nil, formData_594511, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_594494(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_594495, base: "/",
    url: url_PostDescribeAvailabilityOptions_594496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_594477 = ref object of OpenApiRestCall_593437
proc url_GetDescribeAvailabilityOptions_594479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_594478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594480 = query.getOrDefault("Deployed")
  valid_594480 = validateParameter(valid_594480, JBool, required = false, default = nil)
  if valid_594480 != nil:
    section.add "Deployed", valid_594480
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594481 = query.getOrDefault("Action")
  valid_594481 = validateParameter(valid_594481, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_594481 != nil:
    section.add "Action", valid_594481
  var valid_594482 = query.getOrDefault("DomainName")
  valid_594482 = validateParameter(valid_594482, JString, required = true,
                                 default = nil)
  if valid_594482 != nil:
    section.add "DomainName", valid_594482
  var valid_594483 = query.getOrDefault("Version")
  valid_594483 = validateParameter(valid_594483, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594483 != nil:
    section.add "Version", valid_594483
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
  var valid_594484 = header.getOrDefault("X-Amz-Date")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Date", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Security-Token")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Security-Token", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Content-Sha256", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Algorithm")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Algorithm", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Signature")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Signature", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-SignedHeaders", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Credential")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Credential", valid_594490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594491: Call_GetDescribeAvailabilityOptions_594477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594491.validator(path, query, header, formData, body)
  let scheme = call_594491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594491.url(scheme.get, call_594491.host, call_594491.base,
                         call_594491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594491, url, valid)

proc call*(call_594492: Call_GetDescribeAvailabilityOptions_594477;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594493 = newJObject()
  add(query_594493, "Deployed", newJBool(Deployed))
  add(query_594493, "Action", newJString(Action))
  add(query_594493, "DomainName", newJString(DomainName))
  add(query_594493, "Version", newJString(Version))
  result = call_594492.call(nil, query_594493, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_594477(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_594478, base: "/",
    url: url_GetDescribeAvailabilityOptions_594479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_594528 = ref object of OpenApiRestCall_593437
proc url_PostDescribeDomains_594530(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_594529(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594531 = query.getOrDefault("Action")
  valid_594531 = validateParameter(valid_594531, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_594531 != nil:
    section.add "Action", valid_594531
  var valid_594532 = query.getOrDefault("Version")
  valid_594532 = validateParameter(valid_594532, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594532 != nil:
    section.add "Version", valid_594532
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
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Security-Token")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Security-Token", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Content-Sha256", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Signature")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Signature", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-SignedHeaders", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Credential")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Credential", valid_594539
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_594540 = formData.getOrDefault("DomainNames")
  valid_594540 = validateParameter(valid_594540, JArray, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "DomainNames", valid_594540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594541: Call_PostDescribeDomains_594528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594541.validator(path, query, header, formData, body)
  let scheme = call_594541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594541.url(scheme.get, call_594541.host, call_594541.base,
                         call_594541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594541, url, valid)

proc call*(call_594542: Call_PostDescribeDomains_594528;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594543 = newJObject()
  var formData_594544 = newJObject()
  if DomainNames != nil:
    formData_594544.add "DomainNames", DomainNames
  add(query_594543, "Action", newJString(Action))
  add(query_594543, "Version", newJString(Version))
  result = call_594542.call(nil, query_594543, nil, formData_594544, nil)

var postDescribeDomains* = Call_PostDescribeDomains_594528(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_594529, base: "/",
    url: url_PostDescribeDomains_594530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_594512 = ref object of OpenApiRestCall_593437
proc url_GetDescribeDomains_594514(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_594513(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594515 = query.getOrDefault("DomainNames")
  valid_594515 = validateParameter(valid_594515, JArray, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "DomainNames", valid_594515
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594516 = query.getOrDefault("Action")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_594516 != nil:
    section.add "Action", valid_594516
  var valid_594517 = query.getOrDefault("Version")
  valid_594517 = validateParameter(valid_594517, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594517 != nil:
    section.add "Version", valid_594517
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
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Security-Token")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Security-Token", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594525: Call_GetDescribeDomains_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594525.validator(path, query, header, formData, body)
  let scheme = call_594525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594525.url(scheme.get, call_594525.host, call_594525.base,
                         call_594525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594525, url, valid)

proc call*(call_594526: Call_GetDescribeDomains_594512;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594527 = newJObject()
  if DomainNames != nil:
    query_594527.add "DomainNames", DomainNames
  add(query_594527, "Action", newJString(Action))
  add(query_594527, "Version", newJString(Version))
  result = call_594526.call(nil, query_594527, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_594512(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_594513, base: "/",
    url: url_GetDescribeDomains_594514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_594563 = ref object of OpenApiRestCall_593437
proc url_PostDescribeExpressions_594565(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeExpressions_594564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594566 = query.getOrDefault("Action")
  valid_594566 = validateParameter(valid_594566, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_594566 != nil:
    section.add "Action", valid_594566
  var valid_594567 = query.getOrDefault("Version")
  valid_594567 = validateParameter(valid_594567, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594567 != nil:
    section.add "Version", valid_594567
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
  var valid_594568 = header.getOrDefault("X-Amz-Date")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Date", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Security-Token")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Security-Token", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Content-Sha256", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Algorithm")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Algorithm", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Signature")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Signature", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-SignedHeaders", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Credential")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Credential", valid_594574
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594575 = formData.getOrDefault("DomainName")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = nil)
  if valid_594575 != nil:
    section.add "DomainName", valid_594575
  var valid_594576 = formData.getOrDefault("Deployed")
  valid_594576 = validateParameter(valid_594576, JBool, required = false, default = nil)
  if valid_594576 != nil:
    section.add "Deployed", valid_594576
  var valid_594577 = formData.getOrDefault("ExpressionNames")
  valid_594577 = validateParameter(valid_594577, JArray, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "ExpressionNames", valid_594577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594578: Call_PostDescribeExpressions_594563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594578.validator(path, query, header, formData, body)
  let scheme = call_594578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594578.url(scheme.get, call_594578.host, call_594578.base,
                         call_594578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594578, url, valid)

proc call*(call_594579: Call_PostDescribeExpressions_594563; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeExpressions";
          ExpressionNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Version: string (required)
  var query_594580 = newJObject()
  var formData_594581 = newJObject()
  add(formData_594581, "DomainName", newJString(DomainName))
  add(formData_594581, "Deployed", newJBool(Deployed))
  add(query_594580, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_594581.add "ExpressionNames", ExpressionNames
  add(query_594580, "Version", newJString(Version))
  result = call_594579.call(nil, query_594580, nil, formData_594581, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_594563(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_594564, base: "/",
    url: url_PostDescribeExpressions_594565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_594545 = ref object of OpenApiRestCall_593437
proc url_GetDescribeExpressions_594547(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeExpressions_594546(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594548 = query.getOrDefault("Deployed")
  valid_594548 = validateParameter(valid_594548, JBool, required = false, default = nil)
  if valid_594548 != nil:
    section.add "Deployed", valid_594548
  var valid_594549 = query.getOrDefault("ExpressionNames")
  valid_594549 = validateParameter(valid_594549, JArray, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "ExpressionNames", valid_594549
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594550 = query.getOrDefault("Action")
  valid_594550 = validateParameter(valid_594550, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_594550 != nil:
    section.add "Action", valid_594550
  var valid_594551 = query.getOrDefault("DomainName")
  valid_594551 = validateParameter(valid_594551, JString, required = true,
                                 default = nil)
  if valid_594551 != nil:
    section.add "DomainName", valid_594551
  var valid_594552 = query.getOrDefault("Version")
  valid_594552 = validateParameter(valid_594552, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594552 != nil:
    section.add "Version", valid_594552
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
  var valid_594553 = header.getOrDefault("X-Amz-Date")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Date", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Security-Token")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Security-Token", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Content-Sha256", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Algorithm")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Algorithm", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Signature")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Signature", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-SignedHeaders", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Credential")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Credential", valid_594559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594560: Call_GetDescribeExpressions_594545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594560.validator(path, query, header, formData, body)
  let scheme = call_594560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594560.url(scheme.get, call_594560.host, call_594560.base,
                         call_594560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594560, url, valid)

proc call*(call_594561: Call_GetDescribeExpressions_594545; DomainName: string;
          Deployed: bool = false; ExpressionNames: JsonNode = nil;
          Action: string = "DescribeExpressions"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594562 = newJObject()
  add(query_594562, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_594562.add "ExpressionNames", ExpressionNames
  add(query_594562, "Action", newJString(Action))
  add(query_594562, "DomainName", newJString(DomainName))
  add(query_594562, "Version", newJString(Version))
  result = call_594561.call(nil, query_594562, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_594545(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_594546, base: "/",
    url: url_GetDescribeExpressions_594547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_594600 = ref object of OpenApiRestCall_593437
proc url_PostDescribeIndexFields_594602(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_594601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594603 = query.getOrDefault("Action")
  valid_594603 = validateParameter(valid_594603, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_594603 != nil:
    section.add "Action", valid_594603
  var valid_594604 = query.getOrDefault("Version")
  valid_594604 = validateParameter(valid_594604, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594604 != nil:
    section.add "Version", valid_594604
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
  var valid_594605 = header.getOrDefault("X-Amz-Date")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Date", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Security-Token")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Security-Token", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Content-Sha256", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Algorithm")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Algorithm", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Signature")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Signature", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-SignedHeaders", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Credential")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Credential", valid_594611
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594612 = formData.getOrDefault("DomainName")
  valid_594612 = validateParameter(valid_594612, JString, required = true,
                                 default = nil)
  if valid_594612 != nil:
    section.add "DomainName", valid_594612
  var valid_594613 = formData.getOrDefault("Deployed")
  valid_594613 = validateParameter(valid_594613, JBool, required = false, default = nil)
  if valid_594613 != nil:
    section.add "Deployed", valid_594613
  var valid_594614 = formData.getOrDefault("FieldNames")
  valid_594614 = validateParameter(valid_594614, JArray, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "FieldNames", valid_594614
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594615: Call_PostDescribeIndexFields_594600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594615.validator(path, query, header, formData, body)
  let scheme = call_594615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594615.url(scheme.get, call_594615.host, call_594615.base,
                         call_594615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594615, url, valid)

proc call*(call_594616: Call_PostDescribeIndexFields_594600; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeIndexFields";
          FieldNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Version: string (required)
  var query_594617 = newJObject()
  var formData_594618 = newJObject()
  add(formData_594618, "DomainName", newJString(DomainName))
  add(formData_594618, "Deployed", newJBool(Deployed))
  add(query_594617, "Action", newJString(Action))
  if FieldNames != nil:
    formData_594618.add "FieldNames", FieldNames
  add(query_594617, "Version", newJString(Version))
  result = call_594616.call(nil, query_594617, nil, formData_594618, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_594600(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_594601, base: "/",
    url: url_PostDescribeIndexFields_594602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_594582 = ref object of OpenApiRestCall_593437
proc url_GetDescribeIndexFields_594584(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_594583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594585 = query.getOrDefault("Deployed")
  valid_594585 = validateParameter(valid_594585, JBool, required = false, default = nil)
  if valid_594585 != nil:
    section.add "Deployed", valid_594585
  var valid_594586 = query.getOrDefault("FieldNames")
  valid_594586 = validateParameter(valid_594586, JArray, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "FieldNames", valid_594586
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594587 = query.getOrDefault("Action")
  valid_594587 = validateParameter(valid_594587, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_594587 != nil:
    section.add "Action", valid_594587
  var valid_594588 = query.getOrDefault("DomainName")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = nil)
  if valid_594588 != nil:
    section.add "DomainName", valid_594588
  var valid_594589 = query.getOrDefault("Version")
  valid_594589 = validateParameter(valid_594589, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594589 != nil:
    section.add "Version", valid_594589
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
  var valid_594590 = header.getOrDefault("X-Amz-Date")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Date", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Security-Token")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Security-Token", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Content-Sha256", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Algorithm")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Algorithm", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Signature")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Signature", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-SignedHeaders", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Credential")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Credential", valid_594596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594597: Call_GetDescribeIndexFields_594582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594597.validator(path, query, header, formData, body)
  let scheme = call_594597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594597.url(scheme.get, call_594597.host, call_594597.base,
                         call_594597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594597, url, valid)

proc call*(call_594598: Call_GetDescribeIndexFields_594582; DomainName: string;
          Deployed: bool = false; FieldNames: JsonNode = nil;
          Action: string = "DescribeIndexFields"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594599 = newJObject()
  add(query_594599, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_594599.add "FieldNames", FieldNames
  add(query_594599, "Action", newJString(Action))
  add(query_594599, "DomainName", newJString(DomainName))
  add(query_594599, "Version", newJString(Version))
  result = call_594598.call(nil, query_594599, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_594582(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_594583, base: "/",
    url: url_GetDescribeIndexFields_594584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_594635 = ref object of OpenApiRestCall_593437
proc url_PostDescribeScalingParameters_594637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeScalingParameters_594636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594638 = query.getOrDefault("Action")
  valid_594638 = validateParameter(valid_594638, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_594638 != nil:
    section.add "Action", valid_594638
  var valid_594639 = query.getOrDefault("Version")
  valid_594639 = validateParameter(valid_594639, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594639 != nil:
    section.add "Version", valid_594639
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
  var valid_594640 = header.getOrDefault("X-Amz-Date")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Date", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Security-Token")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Security-Token", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Content-Sha256", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Algorithm")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Algorithm", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Signature")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Signature", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-SignedHeaders", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Credential")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Credential", valid_594646
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594647 = formData.getOrDefault("DomainName")
  valid_594647 = validateParameter(valid_594647, JString, required = true,
                                 default = nil)
  if valid_594647 != nil:
    section.add "DomainName", valid_594647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594648: Call_PostDescribeScalingParameters_594635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594648.validator(path, query, header, formData, body)
  let scheme = call_594648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594648.url(scheme.get, call_594648.host, call_594648.base,
                         call_594648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594648, url, valid)

proc call*(call_594649: Call_PostDescribeScalingParameters_594635;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594650 = newJObject()
  var formData_594651 = newJObject()
  add(formData_594651, "DomainName", newJString(DomainName))
  add(query_594650, "Action", newJString(Action))
  add(query_594650, "Version", newJString(Version))
  result = call_594649.call(nil, query_594650, nil, formData_594651, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_594635(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_594636, base: "/",
    url: url_PostDescribeScalingParameters_594637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_594619 = ref object of OpenApiRestCall_593437
proc url_GetDescribeScalingParameters_594621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeScalingParameters_594620(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594622 = query.getOrDefault("Action")
  valid_594622 = validateParameter(valid_594622, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_594622 != nil:
    section.add "Action", valid_594622
  var valid_594623 = query.getOrDefault("DomainName")
  valid_594623 = validateParameter(valid_594623, JString, required = true,
                                 default = nil)
  if valid_594623 != nil:
    section.add "DomainName", valid_594623
  var valid_594624 = query.getOrDefault("Version")
  valid_594624 = validateParameter(valid_594624, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594624 != nil:
    section.add "Version", valid_594624
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
  var valid_594625 = header.getOrDefault("X-Amz-Date")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Date", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Security-Token")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Security-Token", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Content-Sha256", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Algorithm")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Algorithm", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Signature")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Signature", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-SignedHeaders", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Credential")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Credential", valid_594631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594632: Call_GetDescribeScalingParameters_594619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594632.validator(path, query, header, formData, body)
  let scheme = call_594632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594632.url(scheme.get, call_594632.host, call_594632.base,
                         call_594632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594632, url, valid)

proc call*(call_594633: Call_GetDescribeScalingParameters_594619;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594634 = newJObject()
  add(query_594634, "Action", newJString(Action))
  add(query_594634, "DomainName", newJString(DomainName))
  add(query_594634, "Version", newJString(Version))
  result = call_594633.call(nil, query_594634, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_594619(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_594620, base: "/",
    url: url_GetDescribeScalingParameters_594621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_594669 = ref object of OpenApiRestCall_593437
proc url_PostDescribeServiceAccessPolicies_594671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_594670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594672 = query.getOrDefault("Action")
  valid_594672 = validateParameter(valid_594672, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_594672 != nil:
    section.add "Action", valid_594672
  var valid_594673 = query.getOrDefault("Version")
  valid_594673 = validateParameter(valid_594673, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594673 != nil:
    section.add "Version", valid_594673
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
  var valid_594674 = header.getOrDefault("X-Amz-Date")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Date", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Security-Token")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Security-Token", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Content-Sha256", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Algorithm")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Algorithm", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Signature")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Signature", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-SignedHeaders", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Credential")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Credential", valid_594680
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594681 = formData.getOrDefault("DomainName")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = nil)
  if valid_594681 != nil:
    section.add "DomainName", valid_594681
  var valid_594682 = formData.getOrDefault("Deployed")
  valid_594682 = validateParameter(valid_594682, JBool, required = false, default = nil)
  if valid_594682 != nil:
    section.add "Deployed", valid_594682
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594683: Call_PostDescribeServiceAccessPolicies_594669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594683.validator(path, query, header, formData, body)
  let scheme = call_594683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594683.url(scheme.get, call_594683.host, call_594683.base,
                         call_594683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594683, url, valid)

proc call*(call_594684: Call_PostDescribeServiceAccessPolicies_594669;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594685 = newJObject()
  var formData_594686 = newJObject()
  add(formData_594686, "DomainName", newJString(DomainName))
  add(formData_594686, "Deployed", newJBool(Deployed))
  add(query_594685, "Action", newJString(Action))
  add(query_594685, "Version", newJString(Version))
  result = call_594684.call(nil, query_594685, nil, formData_594686, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_594669(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_594670, base: "/",
    url: url_PostDescribeServiceAccessPolicies_594671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_594652 = ref object of OpenApiRestCall_593437
proc url_GetDescribeServiceAccessPolicies_594654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_594653(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_594655 = query.getOrDefault("Deployed")
  valid_594655 = validateParameter(valid_594655, JBool, required = false, default = nil)
  if valid_594655 != nil:
    section.add "Deployed", valid_594655
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594656 = query.getOrDefault("Action")
  valid_594656 = validateParameter(valid_594656, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_594656 != nil:
    section.add "Action", valid_594656
  var valid_594657 = query.getOrDefault("DomainName")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = nil)
  if valid_594657 != nil:
    section.add "DomainName", valid_594657
  var valid_594658 = query.getOrDefault("Version")
  valid_594658 = validateParameter(valid_594658, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594658 != nil:
    section.add "Version", valid_594658
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
  var valid_594659 = header.getOrDefault("X-Amz-Date")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Date", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Security-Token")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Security-Token", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Content-Sha256", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Algorithm")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Algorithm", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Signature")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Signature", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-SignedHeaders", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Credential")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Credential", valid_594665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594666: Call_GetDescribeServiceAccessPolicies_594652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594666.validator(path, query, header, formData, body)
  let scheme = call_594666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594666.url(scheme.get, call_594666.host, call_594666.base,
                         call_594666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594666, url, valid)

proc call*(call_594667: Call_GetDescribeServiceAccessPolicies_594652;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594668 = newJObject()
  add(query_594668, "Deployed", newJBool(Deployed))
  add(query_594668, "Action", newJString(Action))
  add(query_594668, "DomainName", newJString(DomainName))
  add(query_594668, "Version", newJString(Version))
  result = call_594667.call(nil, query_594668, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_594652(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_594653, base: "/",
    url: url_GetDescribeServiceAccessPolicies_594654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_594705 = ref object of OpenApiRestCall_593437
proc url_PostDescribeSuggesters_594707(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSuggesters_594706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594708 = query.getOrDefault("Action")
  valid_594708 = validateParameter(valid_594708, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_594708 != nil:
    section.add "Action", valid_594708
  var valid_594709 = query.getOrDefault("Version")
  valid_594709 = validateParameter(valid_594709, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594709 != nil:
    section.add "Version", valid_594709
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
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Security-Token")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Security-Token", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Content-Sha256", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Algorithm")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Algorithm", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Signature")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Signature", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-SignedHeaders", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Credential")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Credential", valid_594716
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594717 = formData.getOrDefault("DomainName")
  valid_594717 = validateParameter(valid_594717, JString, required = true,
                                 default = nil)
  if valid_594717 != nil:
    section.add "DomainName", valid_594717
  var valid_594718 = formData.getOrDefault("Deployed")
  valid_594718 = validateParameter(valid_594718, JBool, required = false, default = nil)
  if valid_594718 != nil:
    section.add "Deployed", valid_594718
  var valid_594719 = formData.getOrDefault("SuggesterNames")
  valid_594719 = validateParameter(valid_594719, JArray, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "SuggesterNames", valid_594719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594720: Call_PostDescribeSuggesters_594705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594720.validator(path, query, header, formData, body)
  let scheme = call_594720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594720.url(scheme.get, call_594720.host, call_594720.base,
                         call_594720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594720, url, valid)

proc call*(call_594721: Call_PostDescribeSuggesters_594705; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          SuggesterNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Version: string (required)
  var query_594722 = newJObject()
  var formData_594723 = newJObject()
  add(formData_594723, "DomainName", newJString(DomainName))
  add(formData_594723, "Deployed", newJBool(Deployed))
  add(query_594722, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_594723.add "SuggesterNames", SuggesterNames
  add(query_594722, "Version", newJString(Version))
  result = call_594721.call(nil, query_594722, nil, formData_594723, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_594705(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_594706, base: "/",
    url: url_PostDescribeSuggesters_594707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_594687 = ref object of OpenApiRestCall_593437
proc url_GetDescribeSuggesters_594689(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSuggesters_594688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  var valid_594690 = query.getOrDefault("Deployed")
  valid_594690 = validateParameter(valid_594690, JBool, required = false, default = nil)
  if valid_594690 != nil:
    section.add "Deployed", valid_594690
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594691 = query.getOrDefault("Action")
  valid_594691 = validateParameter(valid_594691, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_594691 != nil:
    section.add "Action", valid_594691
  var valid_594692 = query.getOrDefault("DomainName")
  valid_594692 = validateParameter(valid_594692, JString, required = true,
                                 default = nil)
  if valid_594692 != nil:
    section.add "DomainName", valid_594692
  var valid_594693 = query.getOrDefault("Version")
  valid_594693 = validateParameter(valid_594693, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594693 != nil:
    section.add "Version", valid_594693
  var valid_594694 = query.getOrDefault("SuggesterNames")
  valid_594694 = validateParameter(valid_594694, JArray, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "SuggesterNames", valid_594694
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
  var valid_594695 = header.getOrDefault("X-Amz-Date")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Date", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Security-Token")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Security-Token", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Content-Sha256", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Algorithm")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Algorithm", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Signature")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Signature", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-SignedHeaders", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Credential")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Credential", valid_594701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594702: Call_GetDescribeSuggesters_594687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594702.validator(path, query, header, formData, body)
  let scheme = call_594702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594702.url(scheme.get, call_594702.host, call_594702.base,
                         call_594702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594702, url, valid)

proc call*(call_594703: Call_GetDescribeSuggesters_594687; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          Version: string = "2013-01-01"; SuggesterNames: JsonNode = nil): Recallable =
  ## getDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  var query_594704 = newJObject()
  add(query_594704, "Deployed", newJBool(Deployed))
  add(query_594704, "Action", newJString(Action))
  add(query_594704, "DomainName", newJString(DomainName))
  add(query_594704, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_594704.add "SuggesterNames", SuggesterNames
  result = call_594703.call(nil, query_594704, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_594687(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_594688, base: "/",
    url: url_GetDescribeSuggesters_594689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_594740 = ref object of OpenApiRestCall_593437
proc url_PostIndexDocuments_594742(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_594741(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594743 = query.getOrDefault("Action")
  valid_594743 = validateParameter(valid_594743, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_594743 != nil:
    section.add "Action", valid_594743
  var valid_594744 = query.getOrDefault("Version")
  valid_594744 = validateParameter(valid_594744, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594744 != nil:
    section.add "Version", valid_594744
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
  var valid_594745 = header.getOrDefault("X-Amz-Date")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Date", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Security-Token")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Security-Token", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Content-Sha256", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Algorithm")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Algorithm", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Signature")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Signature", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-SignedHeaders", valid_594750
  var valid_594751 = header.getOrDefault("X-Amz-Credential")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Credential", valid_594751
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594752 = formData.getOrDefault("DomainName")
  valid_594752 = validateParameter(valid_594752, JString, required = true,
                                 default = nil)
  if valid_594752 != nil:
    section.add "DomainName", valid_594752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594753: Call_PostIndexDocuments_594740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_594753.validator(path, query, header, formData, body)
  let scheme = call_594753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594753.url(scheme.get, call_594753.host, call_594753.base,
                         call_594753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594753, url, valid)

proc call*(call_594754: Call_PostIndexDocuments_594740; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594755 = newJObject()
  var formData_594756 = newJObject()
  add(formData_594756, "DomainName", newJString(DomainName))
  add(query_594755, "Action", newJString(Action))
  add(query_594755, "Version", newJString(Version))
  result = call_594754.call(nil, query_594755, nil, formData_594756, nil)

var postIndexDocuments* = Call_PostIndexDocuments_594740(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_594741, base: "/",
    url: url_PostIndexDocuments_594742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_594724 = ref object of OpenApiRestCall_593437
proc url_GetIndexDocuments_594726(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_594725(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594727 = query.getOrDefault("Action")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_594727 != nil:
    section.add "Action", valid_594727
  var valid_594728 = query.getOrDefault("DomainName")
  valid_594728 = validateParameter(valid_594728, JString, required = true,
                                 default = nil)
  if valid_594728 != nil:
    section.add "DomainName", valid_594728
  var valid_594729 = query.getOrDefault("Version")
  valid_594729 = validateParameter(valid_594729, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594729 != nil:
    section.add "Version", valid_594729
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
  var valid_594730 = header.getOrDefault("X-Amz-Date")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Date", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Security-Token")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Security-Token", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Content-Sha256", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-Algorithm")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-Algorithm", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Signature")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Signature", valid_594734
  var valid_594735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-SignedHeaders", valid_594735
  var valid_594736 = header.getOrDefault("X-Amz-Credential")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Credential", valid_594736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594737: Call_GetIndexDocuments_594724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_594737.validator(path, query, header, formData, body)
  let scheme = call_594737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594737.url(scheme.get, call_594737.host, call_594737.base,
                         call_594737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594737, url, valid)

proc call*(call_594738: Call_GetIndexDocuments_594724; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594739 = newJObject()
  add(query_594739, "Action", newJString(Action))
  add(query_594739, "DomainName", newJString(DomainName))
  add(query_594739, "Version", newJString(Version))
  result = call_594738.call(nil, query_594739, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_594724(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_594725,
    base: "/", url: url_GetIndexDocuments_594726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_594772 = ref object of OpenApiRestCall_593437
proc url_PostListDomainNames_594774(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomainNames_594773(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594775 = query.getOrDefault("Action")
  valid_594775 = validateParameter(valid_594775, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_594775 != nil:
    section.add "Action", valid_594775
  var valid_594776 = query.getOrDefault("Version")
  valid_594776 = validateParameter(valid_594776, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594776 != nil:
    section.add "Version", valid_594776
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
  var valid_594777 = header.getOrDefault("X-Amz-Date")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Date", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Security-Token")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Security-Token", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Content-Sha256", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Algorithm")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Algorithm", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Signature")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Signature", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-SignedHeaders", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Credential")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Credential", valid_594783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594784: Call_PostListDomainNames_594772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_594784.validator(path, query, header, formData, body)
  let scheme = call_594784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594784.url(scheme.get, call_594784.host, call_594784.base,
                         call_594784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594784, url, valid)

proc call*(call_594785: Call_PostListDomainNames_594772;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594786 = newJObject()
  add(query_594786, "Action", newJString(Action))
  add(query_594786, "Version", newJString(Version))
  result = call_594785.call(nil, query_594786, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_594772(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_594773, base: "/",
    url: url_PostListDomainNames_594774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_594757 = ref object of OpenApiRestCall_593437
proc url_GetListDomainNames_594759(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomainNames_594758(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594760 = query.getOrDefault("Action")
  valid_594760 = validateParameter(valid_594760, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_594760 != nil:
    section.add "Action", valid_594760
  var valid_594761 = query.getOrDefault("Version")
  valid_594761 = validateParameter(valid_594761, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594761 != nil:
    section.add "Version", valid_594761
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
  var valid_594762 = header.getOrDefault("X-Amz-Date")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Date", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Security-Token")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Security-Token", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Content-Sha256", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Algorithm")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Algorithm", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Signature")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Signature", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-SignedHeaders", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-Credential")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Credential", valid_594768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594769: Call_GetListDomainNames_594757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_594769.validator(path, query, header, formData, body)
  let scheme = call_594769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594769.url(scheme.get, call_594769.host, call_594769.base,
                         call_594769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594769, url, valid)

proc call*(call_594770: Call_GetListDomainNames_594757;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594771 = newJObject()
  add(query_594771, "Action", newJString(Action))
  add(query_594771, "Version", newJString(Version))
  result = call_594770.call(nil, query_594771, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_594757(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_594758, base: "/",
    url: url_GetListDomainNames_594759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_594804 = ref object of OpenApiRestCall_593437
proc url_PostUpdateAvailabilityOptions_594806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_594805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594807 = query.getOrDefault("Action")
  valid_594807 = validateParameter(valid_594807, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_594807 != nil:
    section.add "Action", valid_594807
  var valid_594808 = query.getOrDefault("Version")
  valid_594808 = validateParameter(valid_594808, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594808 != nil:
    section.add "Version", valid_594808
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
  var valid_594809 = header.getOrDefault("X-Amz-Date")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Date", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Security-Token")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Security-Token", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Content-Sha256", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Algorithm")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Algorithm", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Signature")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Signature", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-SignedHeaders", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Credential")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Credential", valid_594815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594816 = formData.getOrDefault("DomainName")
  valid_594816 = validateParameter(valid_594816, JString, required = true,
                                 default = nil)
  if valid_594816 != nil:
    section.add "DomainName", valid_594816
  var valid_594817 = formData.getOrDefault("MultiAZ")
  valid_594817 = validateParameter(valid_594817, JBool, required = true, default = nil)
  if valid_594817 != nil:
    section.add "MultiAZ", valid_594817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594818: Call_PostUpdateAvailabilityOptions_594804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594818.validator(path, query, header, formData, body)
  let scheme = call_594818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594818.url(scheme.get, call_594818.host, call_594818.base,
                         call_594818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594818, url, valid)

proc call*(call_594819: Call_PostUpdateAvailabilityOptions_594804;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594820 = newJObject()
  var formData_594821 = newJObject()
  add(formData_594821, "DomainName", newJString(DomainName))
  add(formData_594821, "MultiAZ", newJBool(MultiAZ))
  add(query_594820, "Action", newJString(Action))
  add(query_594820, "Version", newJString(Version))
  result = call_594819.call(nil, query_594820, nil, formData_594821, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_594804(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_594805, base: "/",
    url: url_PostUpdateAvailabilityOptions_594806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_594787 = ref object of OpenApiRestCall_593437
proc url_GetUpdateAvailabilityOptions_594789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_594788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_594790 = query.getOrDefault("MultiAZ")
  valid_594790 = validateParameter(valid_594790, JBool, required = true, default = nil)
  if valid_594790 != nil:
    section.add "MultiAZ", valid_594790
  var valid_594791 = query.getOrDefault("Action")
  valid_594791 = validateParameter(valid_594791, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_594791 != nil:
    section.add "Action", valid_594791
  var valid_594792 = query.getOrDefault("DomainName")
  valid_594792 = validateParameter(valid_594792, JString, required = true,
                                 default = nil)
  if valid_594792 != nil:
    section.add "DomainName", valid_594792
  var valid_594793 = query.getOrDefault("Version")
  valid_594793 = validateParameter(valid_594793, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594793 != nil:
    section.add "Version", valid_594793
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
  var valid_594794 = header.getOrDefault("X-Amz-Date")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Date", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Security-Token")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Security-Token", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Content-Sha256", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Algorithm")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Algorithm", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Signature")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Signature", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-SignedHeaders", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Credential")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Credential", valid_594800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594801: Call_GetUpdateAvailabilityOptions_594787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594801.validator(path, query, header, formData, body)
  let scheme = call_594801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594801.url(scheme.get, call_594801.host, call_594801.base,
                         call_594801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594801, url, valid)

proc call*(call_594802: Call_GetUpdateAvailabilityOptions_594787; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594803 = newJObject()
  add(query_594803, "MultiAZ", newJBool(MultiAZ))
  add(query_594803, "Action", newJString(Action))
  add(query_594803, "DomainName", newJString(DomainName))
  add(query_594803, "Version", newJString(Version))
  result = call_594802.call(nil, query_594803, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_594787(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_594788, base: "/",
    url: url_GetUpdateAvailabilityOptions_594789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_594841 = ref object of OpenApiRestCall_593437
proc url_PostUpdateScalingParameters_594843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateScalingParameters_594842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594844 = query.getOrDefault("Action")
  valid_594844 = validateParameter(valid_594844, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_594844 != nil:
    section.add "Action", valid_594844
  var valid_594845 = query.getOrDefault("Version")
  valid_594845 = validateParameter(valid_594845, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594845 != nil:
    section.add "Version", valid_594845
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
  var valid_594846 = header.getOrDefault("X-Amz-Date")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Date", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Security-Token")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Security-Token", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Content-Sha256", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Algorithm")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Algorithm", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Signature")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Signature", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-SignedHeaders", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-Credential")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Credential", valid_594852
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594853 = formData.getOrDefault("DomainName")
  valid_594853 = validateParameter(valid_594853, JString, required = true,
                                 default = nil)
  if valid_594853 != nil:
    section.add "DomainName", valid_594853
  var valid_594854 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_594854
  var valid_594855 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_594855
  var valid_594856 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_594856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594857: Call_PostUpdateScalingParameters_594841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594857.validator(path, query, header, formData, body)
  let scheme = call_594857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594857.url(scheme.get, call_594857.host, call_594857.base,
                         call_594857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594857, url, valid)

proc call*(call_594858: Call_PostUpdateScalingParameters_594841;
          DomainName: string; ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Version: string (required)
  var query_594859 = newJObject()
  var formData_594860 = newJObject()
  add(formData_594860, "DomainName", newJString(DomainName))
  add(formData_594860, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_594859, "Action", newJString(Action))
  add(formData_594860, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_594860, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_594859, "Version", newJString(Version))
  result = call_594858.call(nil, query_594859, nil, formData_594860, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_594841(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_594842, base: "/",
    url: url_PostUpdateScalingParameters_594843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_594822 = ref object of OpenApiRestCall_593437
proc url_GetUpdateScalingParameters_594824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateScalingParameters_594823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  var valid_594825 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_594825
  var valid_594826 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_594826
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594827 = query.getOrDefault("Action")
  valid_594827 = validateParameter(valid_594827, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_594827 != nil:
    section.add "Action", valid_594827
  var valid_594828 = query.getOrDefault("DomainName")
  valid_594828 = validateParameter(valid_594828, JString, required = true,
                                 default = nil)
  if valid_594828 != nil:
    section.add "DomainName", valid_594828
  var valid_594829 = query.getOrDefault("Version")
  valid_594829 = validateParameter(valid_594829, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594829 != nil:
    section.add "Version", valid_594829
  var valid_594830 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_594830
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
  var valid_594831 = header.getOrDefault("X-Amz-Date")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Date", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Security-Token")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Security-Token", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Content-Sha256", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Algorithm")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Algorithm", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Signature")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Signature", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-SignedHeaders", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Credential")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Credential", valid_594837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594838: Call_GetUpdateScalingParameters_594822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_594838.validator(path, query, header, formData, body)
  let scheme = call_594838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594838.url(scheme.get, call_594838.host, call_594838.base,
                         call_594838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594838, url, valid)

proc call*(call_594839: Call_GetUpdateScalingParameters_594822; DomainName: string;
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          Version: string = "2013-01-01";
          ScalingParametersDesiredInstanceType: string = ""): Recallable =
  ## getUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  var query_594840 = newJObject()
  add(query_594840, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_594840, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_594840, "Action", newJString(Action))
  add(query_594840, "DomainName", newJString(DomainName))
  add(query_594840, "Version", newJString(Version))
  add(query_594840, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_594839.call(nil, query_594840, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_594822(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_594823, base: "/",
    url: url_GetUpdateScalingParameters_594824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_594878 = ref object of OpenApiRestCall_593437
proc url_PostUpdateServiceAccessPolicies_594880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_594879(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594881 = query.getOrDefault("Action")
  valid_594881 = validateParameter(valid_594881, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_594881 != nil:
    section.add "Action", valid_594881
  var valid_594882 = query.getOrDefault("Version")
  valid_594882 = validateParameter(valid_594882, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594882 != nil:
    section.add "Version", valid_594882
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
  var valid_594883 = header.getOrDefault("X-Amz-Date")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Date", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Security-Token")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Security-Token", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Content-Sha256", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Algorithm")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Algorithm", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Signature")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Signature", valid_594887
  var valid_594888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "X-Amz-SignedHeaders", valid_594888
  var valid_594889 = header.getOrDefault("X-Amz-Credential")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Credential", valid_594889
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594890 = formData.getOrDefault("DomainName")
  valid_594890 = validateParameter(valid_594890, JString, required = true,
                                 default = nil)
  if valid_594890 != nil:
    section.add "DomainName", valid_594890
  var valid_594891 = formData.getOrDefault("AccessPolicies")
  valid_594891 = validateParameter(valid_594891, JString, required = true,
                                 default = nil)
  if valid_594891 != nil:
    section.add "AccessPolicies", valid_594891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594892: Call_PostUpdateServiceAccessPolicies_594878;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_594892.validator(path, query, header, formData, body)
  let scheme = call_594892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594892.url(scheme.get, call_594892.host, call_594892.base,
                         call_594892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594892, url, valid)

proc call*(call_594893: Call_PostUpdateServiceAccessPolicies_594878;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594894 = newJObject()
  var formData_594895 = newJObject()
  add(formData_594895, "DomainName", newJString(DomainName))
  add(formData_594895, "AccessPolicies", newJString(AccessPolicies))
  add(query_594894, "Action", newJString(Action))
  add(query_594894, "Version", newJString(Version))
  result = call_594893.call(nil, query_594894, nil, formData_594895, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_594878(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_594879, base: "/",
    url: url_PostUpdateServiceAccessPolicies_594880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_594861 = ref object of OpenApiRestCall_593437
proc url_GetUpdateServiceAccessPolicies_594863(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_594862(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594864 = query.getOrDefault("Action")
  valid_594864 = validateParameter(valid_594864, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_594864 != nil:
    section.add "Action", valid_594864
  var valid_594865 = query.getOrDefault("AccessPolicies")
  valid_594865 = validateParameter(valid_594865, JString, required = true,
                                 default = nil)
  if valid_594865 != nil:
    section.add "AccessPolicies", valid_594865
  var valid_594866 = query.getOrDefault("DomainName")
  valid_594866 = validateParameter(valid_594866, JString, required = true,
                                 default = nil)
  if valid_594866 != nil:
    section.add "DomainName", valid_594866
  var valid_594867 = query.getOrDefault("Version")
  valid_594867 = validateParameter(valid_594867, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_594867 != nil:
    section.add "Version", valid_594867
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
  var valid_594868 = header.getOrDefault("X-Amz-Date")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Date", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Security-Token")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Security-Token", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Content-Sha256", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-Algorithm")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Algorithm", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Signature")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Signature", valid_594872
  var valid_594873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-SignedHeaders", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-Credential")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Credential", valid_594874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594875: Call_GetUpdateServiceAccessPolicies_594861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_594875.validator(path, query, header, formData, body)
  let scheme = call_594875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594875.url(scheme.get, call_594875.host, call_594875.base,
                         call_594875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594875, url, valid)

proc call*(call_594876: Call_GetUpdateServiceAccessPolicies_594861;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_594877 = newJObject()
  add(query_594877, "Action", newJString(Action))
  add(query_594877, "AccessPolicies", newJString(AccessPolicies))
  add(query_594877, "DomainName", newJString(DomainName))
  add(query_594877, "Version", newJString(Version))
  result = call_594876.call(nil, query_594877, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_594861(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_594862, base: "/",
    url: url_GetUpdateServiceAccessPolicies_594863,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
