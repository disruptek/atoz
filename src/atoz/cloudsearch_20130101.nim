
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  Call_PostBuildSuggesters_601045 = ref object of OpenApiRestCall_600437
proc url_PostBuildSuggesters_601047(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBuildSuggesters_601046(path: JsonNode; query: JsonNode;
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
  var valid_601048 = query.getOrDefault("Action")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_601048 != nil:
    section.add "Action", valid_601048
  var valid_601049 = query.getOrDefault("Version")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601049 != nil:
    section.add "Version", valid_601049
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
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601057 = formData.getOrDefault("DomainName")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "DomainName", valid_601057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_PostBuildSuggesters_601045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_PostBuildSuggesters_601045; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601060 = newJObject()
  var formData_601061 = newJObject()
  add(formData_601061, "DomainName", newJString(DomainName))
  add(query_601060, "Action", newJString(Action))
  add(query_601060, "Version", newJString(Version))
  result = call_601059.call(nil, query_601060, nil, formData_601061, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_601045(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_601046, base: "/",
    url: url_PostBuildSuggesters_601047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_600774 = ref object of OpenApiRestCall_600437
proc url_GetBuildSuggesters_600776(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuildSuggesters_600775(path: JsonNode; query: JsonNode;
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
  var valid_600901 = query.getOrDefault("Action")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_600901 != nil:
    section.add "Action", valid_600901
  var valid_600902 = query.getOrDefault("DomainName")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = nil)
  if valid_600902 != nil:
    section.add "DomainName", valid_600902
  var valid_600903 = query.getOrDefault("Version")
  valid_600903 = validateParameter(valid_600903, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600903 != nil:
    section.add "Version", valid_600903
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
  var valid_600904 = header.getOrDefault("X-Amz-Date")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Date", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Security-Token")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Security-Token", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Content-Sha256", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Algorithm")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Algorithm", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Signature")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Signature", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-SignedHeaders", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Credential")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Credential", valid_600910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_GetBuildSuggesters_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600933, url, valid)

proc call*(call_601004: Call_GetBuildSuggesters_600774; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_601005 = newJObject()
  add(query_601005, "Action", newJString(Action))
  add(query_601005, "DomainName", newJString(DomainName))
  add(query_601005, "Version", newJString(Version))
  result = call_601004.call(nil, query_601005, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_600774(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_600775, base: "/",
    url: url_GetBuildSuggesters_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_601078 = ref object of OpenApiRestCall_600437
proc url_PostCreateDomain_601080(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_601079(path: JsonNode; query: JsonNode;
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
  var valid_601081 = query.getOrDefault("Action")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601081 != nil:
    section.add "Action", valid_601081
  var valid_601082 = query.getOrDefault("Version")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601082 != nil:
    section.add "Version", valid_601082
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
  var valid_601083 = header.getOrDefault("X-Amz-Date")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Date", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Security-Token")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Security-Token", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Content-Sha256", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Algorithm")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Algorithm", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Signature", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-SignedHeaders", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Credential")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Credential", valid_601089
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601090 = formData.getOrDefault("DomainName")
  valid_601090 = validateParameter(valid_601090, JString, required = true,
                                 default = nil)
  if valid_601090 != nil:
    section.add "DomainName", valid_601090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601091: Call_PostCreateDomain_601078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601091.validator(path, query, header, formData, body)
  let scheme = call_601091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601091.url(scheme.get, call_601091.host, call_601091.base,
                         call_601091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601091, url, valid)

proc call*(call_601092: Call_PostCreateDomain_601078; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601093 = newJObject()
  var formData_601094 = newJObject()
  add(formData_601094, "DomainName", newJString(DomainName))
  add(query_601093, "Action", newJString(Action))
  add(query_601093, "Version", newJString(Version))
  result = call_601092.call(nil, query_601093, nil, formData_601094, nil)

var postCreateDomain* = Call_PostCreateDomain_601078(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_601079,
    base: "/", url: url_PostCreateDomain_601080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_601062 = ref object of OpenApiRestCall_600437
proc url_GetCreateDomain_601064(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_601063(path: JsonNode; query: JsonNode;
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
  var valid_601065 = query.getOrDefault("Action")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601065 != nil:
    section.add "Action", valid_601065
  var valid_601066 = query.getOrDefault("DomainName")
  valid_601066 = validateParameter(valid_601066, JString, required = true,
                                 default = nil)
  if valid_601066 != nil:
    section.add "DomainName", valid_601066
  var valid_601067 = query.getOrDefault("Version")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601067 != nil:
    section.add "Version", valid_601067
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
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_GetCreateDomain_601062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_GetCreateDomain_601062; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_601077 = newJObject()
  add(query_601077, "Action", newJString(Action))
  add(query_601077, "DomainName", newJString(DomainName))
  add(query_601077, "Version", newJString(Version))
  result = call_601076.call(nil, query_601077, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_601062(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_601063,
    base: "/", url: url_GetCreateDomain_601064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_601114 = ref object of OpenApiRestCall_600437
proc url_PostDefineAnalysisScheme_601116(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineAnalysisScheme_601115(path: JsonNode; query: JsonNode;
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
  var valid_601117 = query.getOrDefault("Action")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_601117 != nil:
    section.add "Action", valid_601117
  var valid_601118 = query.getOrDefault("Version")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601118 != nil:
    section.add "Version", valid_601118
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
  var valid_601119 = header.getOrDefault("X-Amz-Date")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Date", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Security-Token")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Security-Token", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Content-Sha256", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Algorithm")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Algorithm", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Signature")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Signature", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-SignedHeaders", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Credential")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Credential", valid_601125
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
  var valid_601126 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_601126
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601127 = formData.getOrDefault("DomainName")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "DomainName", valid_601127
  var valid_601128 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_601128
  var valid_601129 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_601129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_PostDefineAnalysisScheme_601114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_PostDefineAnalysisScheme_601114; DomainName: string;
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
  var query_601132 = newJObject()
  var formData_601133 = newJObject()
  add(formData_601133, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_601133, "DomainName", newJString(DomainName))
  add(formData_601133, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_601132, "Action", newJString(Action))
  add(formData_601133, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_601132, "Version", newJString(Version))
  result = call_601131.call(nil, query_601132, nil, formData_601133, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_601114(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_601115, base: "/",
    url: url_PostDefineAnalysisScheme_601116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_601095 = ref object of OpenApiRestCall_600437
proc url_GetDefineAnalysisScheme_601097(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineAnalysisScheme_601096(path: JsonNode; query: JsonNode;
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
  var valid_601098 = query.getOrDefault("Action")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_601098 != nil:
    section.add "Action", valid_601098
  var valid_601099 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_601099
  var valid_601100 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_601100
  var valid_601101 = query.getOrDefault("DomainName")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "DomainName", valid_601101
  var valid_601102 = query.getOrDefault("Version")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601102 != nil:
    section.add "Version", valid_601102
  var valid_601103 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_601103
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
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_GetDefineAnalysisScheme_601095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_GetDefineAnalysisScheme_601095; DomainName: string;
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
  var query_601113 = newJObject()
  add(query_601113, "Action", newJString(Action))
  add(query_601113, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_601113, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_601113, "DomainName", newJString(DomainName))
  add(query_601113, "Version", newJString(Version))
  add(query_601113, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_601112.call(nil, query_601113, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_601095(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_601096, base: "/",
    url: url_GetDefineAnalysisScheme_601097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_601152 = ref object of OpenApiRestCall_600437
proc url_PostDefineExpression_601154(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineExpression_601153(path: JsonNode; query: JsonNode;
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
  var valid_601155 = query.getOrDefault("Action")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_601155 != nil:
    section.add "Action", valid_601155
  var valid_601156 = query.getOrDefault("Version")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601156 != nil:
    section.add "Version", valid_601156
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
  var valid_601157 = header.getOrDefault("X-Amz-Date")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Date", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Security-Token")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Security-Token", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Content-Sha256", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Algorithm")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Algorithm", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Signature")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Signature", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-SignedHeaders", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Credential")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Credential", valid_601163
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
  var valid_601164 = formData.getOrDefault("DomainName")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "DomainName", valid_601164
  var valid_601165 = formData.getOrDefault("Expression.ExpressionName")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "Expression.ExpressionName", valid_601165
  var valid_601166 = formData.getOrDefault("Expression.ExpressionValue")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "Expression.ExpressionValue", valid_601166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_PostDefineExpression_601152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_PostDefineExpression_601152; DomainName: string;
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
  var query_601169 = newJObject()
  var formData_601170 = newJObject()
  add(formData_601170, "DomainName", newJString(DomainName))
  add(formData_601170, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_601170, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_601169, "Action", newJString(Action))
  add(query_601169, "Version", newJString(Version))
  result = call_601168.call(nil, query_601169, nil, formData_601170, nil)

var postDefineExpression* = Call_PostDefineExpression_601152(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_601153, base: "/",
    url: url_PostDefineExpression_601154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_601134 = ref object of OpenApiRestCall_600437
proc url_GetDefineExpression_601136(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineExpression_601135(path: JsonNode; query: JsonNode;
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
  var valid_601137 = query.getOrDefault("Action")
  valid_601137 = validateParameter(valid_601137, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_601137 != nil:
    section.add "Action", valid_601137
  var valid_601138 = query.getOrDefault("Expression.ExpressionValue")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "Expression.ExpressionValue", valid_601138
  var valid_601139 = query.getOrDefault("Expression.ExpressionName")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "Expression.ExpressionName", valid_601139
  var valid_601140 = query.getOrDefault("DomainName")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = nil)
  if valid_601140 != nil:
    section.add "DomainName", valid_601140
  var valid_601141 = query.getOrDefault("Version")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601141 != nil:
    section.add "Version", valid_601141
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
  var valid_601142 = header.getOrDefault("X-Amz-Date")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Date", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Security-Token")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Security-Token", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Content-Sha256", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Algorithm")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Algorithm", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Signature")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Signature", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-SignedHeaders", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Credential")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Credential", valid_601148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601149: Call_GetDefineExpression_601134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601149.validator(path, query, header, formData, body)
  let scheme = call_601149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601149.url(scheme.get, call_601149.host, call_601149.base,
                         call_601149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601149, url, valid)

proc call*(call_601150: Call_GetDefineExpression_601134; DomainName: string;
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
  var query_601151 = newJObject()
  add(query_601151, "Action", newJString(Action))
  add(query_601151, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_601151, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_601151, "DomainName", newJString(DomainName))
  add(query_601151, "Version", newJString(Version))
  result = call_601150.call(nil, query_601151, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_601134(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_601135, base: "/",
    url: url_GetDefineExpression_601136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_601200 = ref object of OpenApiRestCall_600437
proc url_PostDefineIndexField_601202(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_601201(path: JsonNode; query: JsonNode;
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
  var valid_601203 = query.getOrDefault("Action")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_601203 != nil:
    section.add "Action", valid_601203
  var valid_601204 = query.getOrDefault("Version")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601204 != nil:
    section.add "Version", valid_601204
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
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Content-Sha256", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Algorithm")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Algorithm", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Signature")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Signature", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-SignedHeaders", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Credential")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Credential", valid_601211
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
  var valid_601212 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "IndexField.TextArrayOptions", valid_601212
  var valid_601213 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "IndexField.DateArrayOptions", valid_601213
  var valid_601214 = formData.getOrDefault("IndexField.TextOptions")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "IndexField.TextOptions", valid_601214
  var valid_601215 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "IndexField.DoubleOptions", valid_601215
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601216 = formData.getOrDefault("DomainName")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "DomainName", valid_601216
  var valid_601217 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "IndexField.LiteralOptions", valid_601217
  var valid_601218 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_601218
  var valid_601219 = formData.getOrDefault("IndexField.DateOptions")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "IndexField.DateOptions", valid_601219
  var valid_601220 = formData.getOrDefault("IndexField.IntOptions")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "IndexField.IntOptions", valid_601220
  var valid_601221 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "IndexField.LatLonOptions", valid_601221
  var valid_601222 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "IndexField.IndexFieldType", valid_601222
  var valid_601223 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_601223
  var valid_601224 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "IndexField.IndexFieldName", valid_601224
  var valid_601225 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "IndexField.IntArrayOptions", valid_601225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_PostDefineIndexField_601200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601226, url, valid)

proc call*(call_601227: Call_PostDefineIndexField_601200; DomainName: string;
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
  var query_601228 = newJObject()
  var formData_601229 = newJObject()
  add(formData_601229, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_601229, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_601229, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_601229, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_601229, "DomainName", newJString(DomainName))
  add(formData_601229, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_601229, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_601229, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_601229, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_601229, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_601229, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_601228, "Action", newJString(Action))
  add(formData_601229, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_601229, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_601228, "Version", newJString(Version))
  add(formData_601229, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_601227.call(nil, query_601228, nil, formData_601229, nil)

var postDefineIndexField* = Call_PostDefineIndexField_601200(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_601201, base: "/",
    url: url_PostDefineIndexField_601202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_601171 = ref object of OpenApiRestCall_600437
proc url_GetDefineIndexField_601173(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_601172(path: JsonNode; query: JsonNode;
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
  var valid_601174 = query.getOrDefault("IndexField.TextOptions")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "IndexField.TextOptions", valid_601174
  var valid_601175 = query.getOrDefault("IndexField.DateOptions")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "IndexField.DateOptions", valid_601175
  var valid_601176 = query.getOrDefault("IndexField.LiteralOptions")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "IndexField.LiteralOptions", valid_601176
  var valid_601177 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_601177
  var valid_601178 = query.getOrDefault("IndexField.IndexFieldType")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "IndexField.IndexFieldType", valid_601178
  var valid_601179 = query.getOrDefault("IndexField.IntOptions")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "IndexField.IntOptions", valid_601179
  var valid_601180 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "IndexField.DateArrayOptions", valid_601180
  var valid_601181 = query.getOrDefault("IndexField.DoubleOptions")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "IndexField.DoubleOptions", valid_601181
  var valid_601182 = query.getOrDefault("IndexField.IndexFieldName")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "IndexField.IndexFieldName", valid_601182
  var valid_601183 = query.getOrDefault("IndexField.LatLonOptions")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "IndexField.LatLonOptions", valid_601183
  var valid_601184 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "IndexField.IntArrayOptions", valid_601184
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601185 = query.getOrDefault("Action")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_601185 != nil:
    section.add "Action", valid_601185
  var valid_601186 = query.getOrDefault("DomainName")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "DomainName", valid_601186
  var valid_601187 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "IndexField.TextArrayOptions", valid_601187
  var valid_601188 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_601188
  var valid_601189 = query.getOrDefault("Version")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601189 != nil:
    section.add "Version", valid_601189
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Content-Sha256", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Algorithm")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Algorithm", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Signature")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Signature", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-SignedHeaders", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Credential")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Credential", valid_601196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601197: Call_GetDefineIndexField_601171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601197.validator(path, query, header, formData, body)
  let scheme = call_601197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601197.url(scheme.get, call_601197.host, call_601197.base,
                         call_601197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601197, url, valid)

proc call*(call_601198: Call_GetDefineIndexField_601171; DomainName: string;
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
  var query_601199 = newJObject()
  add(query_601199, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_601199, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_601199, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_601199, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_601199, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_601199, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_601199, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_601199, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_601199, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_601199, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_601199, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_601199, "Action", newJString(Action))
  add(query_601199, "DomainName", newJString(DomainName))
  add(query_601199, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_601199, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_601199, "Version", newJString(Version))
  result = call_601198.call(nil, query_601199, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_601171(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_601172, base: "/",
    url: url_GetDefineIndexField_601173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_601248 = ref object of OpenApiRestCall_600437
proc url_PostDefineSuggester_601250(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineSuggester_601249(path: JsonNode; query: JsonNode;
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
  var valid_601251 = query.getOrDefault("Action")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_601251 != nil:
    section.add "Action", valid_601251
  var valid_601252 = query.getOrDefault("Version")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601252 != nil:
    section.add "Version", valid_601252
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
  var valid_601253 = header.getOrDefault("X-Amz-Date")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Date", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Security-Token")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Security-Token", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Content-Sha256", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Algorithm")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Algorithm", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Signature")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Signature", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-SignedHeaders", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Credential")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Credential", valid_601259
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
  var valid_601260 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_601260
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601261 = formData.getOrDefault("DomainName")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "DomainName", valid_601261
  var valid_601262 = formData.getOrDefault("Suggester.SuggesterName")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "Suggester.SuggesterName", valid_601262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601263: Call_PostDefineSuggester_601248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601263.validator(path, query, header, formData, body)
  let scheme = call_601263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601263.url(scheme.get, call_601263.host, call_601263.base,
                         call_601263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601263, url, valid)

proc call*(call_601264: Call_PostDefineSuggester_601248; DomainName: string;
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
  var query_601265 = newJObject()
  var formData_601266 = newJObject()
  add(formData_601266, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_601266, "DomainName", newJString(DomainName))
  add(query_601265, "Action", newJString(Action))
  add(query_601265, "Version", newJString(Version))
  add(formData_601266, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_601264.call(nil, query_601265, nil, formData_601266, nil)

var postDefineSuggester* = Call_PostDefineSuggester_601248(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_601249, base: "/",
    url: url_PostDefineSuggester_601250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_601230 = ref object of OpenApiRestCall_600437
proc url_GetDefineSuggester_601232(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineSuggester_601231(path: JsonNode; query: JsonNode;
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
  var valid_601233 = query.getOrDefault("Suggester.SuggesterName")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "Suggester.SuggesterName", valid_601233
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601234 = query.getOrDefault("Action")
  valid_601234 = validateParameter(valid_601234, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_601234 != nil:
    section.add "Action", valid_601234
  var valid_601235 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_601235
  var valid_601236 = query.getOrDefault("DomainName")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = nil)
  if valid_601236 != nil:
    section.add "DomainName", valid_601236
  var valid_601237 = query.getOrDefault("Version")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601237 != nil:
    section.add "Version", valid_601237
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
  var valid_601238 = header.getOrDefault("X-Amz-Date")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Date", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Security-Token")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Security-Token", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Content-Sha256", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Algorithm")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Algorithm", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Signature")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Signature", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-SignedHeaders", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Credential")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Credential", valid_601244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601245: Call_GetDefineSuggester_601230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601245.validator(path, query, header, formData, body)
  let scheme = call_601245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601245.url(scheme.get, call_601245.host, call_601245.base,
                         call_601245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601245, url, valid)

proc call*(call_601246: Call_GetDefineSuggester_601230; DomainName: string;
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
  var query_601247 = newJObject()
  add(query_601247, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_601247, "Action", newJString(Action))
  add(query_601247, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_601247, "DomainName", newJString(DomainName))
  add(query_601247, "Version", newJString(Version))
  result = call_601246.call(nil, query_601247, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_601230(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_601231, base: "/",
    url: url_GetDefineSuggester_601232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_601284 = ref object of OpenApiRestCall_600437
proc url_PostDeleteAnalysisScheme_601286(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnalysisScheme_601285(path: JsonNode; query: JsonNode;
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
  var valid_601287 = query.getOrDefault("Action")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_601287 != nil:
    section.add "Action", valid_601287
  var valid_601288 = query.getOrDefault("Version")
  valid_601288 = validateParameter(valid_601288, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601288 != nil:
    section.add "Version", valid_601288
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
  var valid_601289 = header.getOrDefault("X-Amz-Date")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Date", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Security-Token")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Security-Token", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Content-Sha256", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Algorithm")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Algorithm", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Signature")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Signature", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-SignedHeaders", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Credential")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Credential", valid_601295
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601296 = formData.getOrDefault("DomainName")
  valid_601296 = validateParameter(valid_601296, JString, required = true,
                                 default = nil)
  if valid_601296 != nil:
    section.add "DomainName", valid_601296
  var valid_601297 = formData.getOrDefault("AnalysisSchemeName")
  valid_601297 = validateParameter(valid_601297, JString, required = true,
                                 default = nil)
  if valid_601297 != nil:
    section.add "AnalysisSchemeName", valid_601297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601298: Call_PostDeleteAnalysisScheme_601284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601298.validator(path, query, header, formData, body)
  let scheme = call_601298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601298.url(scheme.get, call_601298.host, call_601298.base,
                         call_601298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601298, url, valid)

proc call*(call_601299: Call_PostDeleteAnalysisScheme_601284; DomainName: string;
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
  var query_601300 = newJObject()
  var formData_601301 = newJObject()
  add(formData_601301, "DomainName", newJString(DomainName))
  add(formData_601301, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_601300, "Action", newJString(Action))
  add(query_601300, "Version", newJString(Version))
  result = call_601299.call(nil, query_601300, nil, formData_601301, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_601284(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_601285, base: "/",
    url: url_PostDeleteAnalysisScheme_601286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_601267 = ref object of OpenApiRestCall_600437
proc url_GetDeleteAnalysisScheme_601269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnalysisScheme_601268(path: JsonNode; query: JsonNode;
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
  var valid_601270 = query.getOrDefault("Action")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_601270 != nil:
    section.add "Action", valid_601270
  var valid_601271 = query.getOrDefault("DomainName")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = nil)
  if valid_601271 != nil:
    section.add "DomainName", valid_601271
  var valid_601272 = query.getOrDefault("AnalysisSchemeName")
  valid_601272 = validateParameter(valid_601272, JString, required = true,
                                 default = nil)
  if valid_601272 != nil:
    section.add "AnalysisSchemeName", valid_601272
  var valid_601273 = query.getOrDefault("Version")
  valid_601273 = validateParameter(valid_601273, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601273 != nil:
    section.add "Version", valid_601273
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
  var valid_601274 = header.getOrDefault("X-Amz-Date")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Date", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Security-Token")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Security-Token", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Content-Sha256", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Algorithm")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Algorithm", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Signature")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Signature", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-SignedHeaders", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Credential")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Credential", valid_601280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_GetDeleteAnalysisScheme_601267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_GetDeleteAnalysisScheme_601267; DomainName: string;
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
  var query_601283 = newJObject()
  add(query_601283, "Action", newJString(Action))
  add(query_601283, "DomainName", newJString(DomainName))
  add(query_601283, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_601283, "Version", newJString(Version))
  result = call_601282.call(nil, query_601283, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_601267(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_601268, base: "/",
    url: url_GetDeleteAnalysisScheme_601269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_601318 = ref object of OpenApiRestCall_600437
proc url_PostDeleteDomain_601320(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_601319(path: JsonNode; query: JsonNode;
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
  var valid_601321 = query.getOrDefault("Action")
  valid_601321 = validateParameter(valid_601321, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601321 != nil:
    section.add "Action", valid_601321
  var valid_601322 = query.getOrDefault("Version")
  valid_601322 = validateParameter(valid_601322, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601322 != nil:
    section.add "Version", valid_601322
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
  var valid_601323 = header.getOrDefault("X-Amz-Date")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Date", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Security-Token")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Security-Token", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Content-Sha256", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Algorithm")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Algorithm", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Signature")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Signature", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-SignedHeaders", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Credential")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Credential", valid_601329
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601330 = formData.getOrDefault("DomainName")
  valid_601330 = validateParameter(valid_601330, JString, required = true,
                                 default = nil)
  if valid_601330 != nil:
    section.add "DomainName", valid_601330
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601331: Call_PostDeleteDomain_601318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601331.validator(path, query, header, formData, body)
  let scheme = call_601331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601331.url(scheme.get, call_601331.host, call_601331.base,
                         call_601331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601331, url, valid)

proc call*(call_601332: Call_PostDeleteDomain_601318; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601333 = newJObject()
  var formData_601334 = newJObject()
  add(formData_601334, "DomainName", newJString(DomainName))
  add(query_601333, "Action", newJString(Action))
  add(query_601333, "Version", newJString(Version))
  result = call_601332.call(nil, query_601333, nil, formData_601334, nil)

var postDeleteDomain* = Call_PostDeleteDomain_601318(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_601319,
    base: "/", url: url_PostDeleteDomain_601320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_601302 = ref object of OpenApiRestCall_600437
proc url_GetDeleteDomain_601304(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_601303(path: JsonNode; query: JsonNode;
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
  var valid_601305 = query.getOrDefault("Action")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601305 != nil:
    section.add "Action", valid_601305
  var valid_601306 = query.getOrDefault("DomainName")
  valid_601306 = validateParameter(valid_601306, JString, required = true,
                                 default = nil)
  if valid_601306 != nil:
    section.add "DomainName", valid_601306
  var valid_601307 = query.getOrDefault("Version")
  valid_601307 = validateParameter(valid_601307, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601307 != nil:
    section.add "Version", valid_601307
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
  var valid_601308 = header.getOrDefault("X-Amz-Date")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Date", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Security-Token")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Security-Token", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Content-Sha256", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Algorithm")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Algorithm", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Signature")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Signature", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-SignedHeaders", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Credential")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Credential", valid_601314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601315: Call_GetDeleteDomain_601302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601315.validator(path, query, header, formData, body)
  let scheme = call_601315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601315.url(scheme.get, call_601315.host, call_601315.base,
                         call_601315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601315, url, valid)

proc call*(call_601316: Call_GetDeleteDomain_601302; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_601317 = newJObject()
  add(query_601317, "Action", newJString(Action))
  add(query_601317, "DomainName", newJString(DomainName))
  add(query_601317, "Version", newJString(Version))
  result = call_601316.call(nil, query_601317, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_601302(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_601303,
    base: "/", url: url_GetDeleteDomain_601304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_601352 = ref object of OpenApiRestCall_600437
proc url_PostDeleteExpression_601354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteExpression_601353(path: JsonNode; query: JsonNode;
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
  var valid_601355 = query.getOrDefault("Action")
  valid_601355 = validateParameter(valid_601355, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_601355 != nil:
    section.add "Action", valid_601355
  var valid_601356 = query.getOrDefault("Version")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601356 != nil:
    section.add "Version", valid_601356
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
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_601364 = formData.getOrDefault("ExpressionName")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = nil)
  if valid_601364 != nil:
    section.add "ExpressionName", valid_601364
  var valid_601365 = formData.getOrDefault("DomainName")
  valid_601365 = validateParameter(valid_601365, JString, required = true,
                                 default = nil)
  if valid_601365 != nil:
    section.add "DomainName", valid_601365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_PostDeleteExpression_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601366, url, valid)

proc call*(call_601367: Call_PostDeleteExpression_601352; ExpressionName: string;
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
  var query_601368 = newJObject()
  var formData_601369 = newJObject()
  add(formData_601369, "ExpressionName", newJString(ExpressionName))
  add(formData_601369, "DomainName", newJString(DomainName))
  add(query_601368, "Action", newJString(Action))
  add(query_601368, "Version", newJString(Version))
  result = call_601367.call(nil, query_601368, nil, formData_601369, nil)

var postDeleteExpression* = Call_PostDeleteExpression_601352(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_601353, base: "/",
    url: url_PostDeleteExpression_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_601335 = ref object of OpenApiRestCall_600437
proc url_GetDeleteExpression_601337(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteExpression_601336(path: JsonNode; query: JsonNode;
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
  var valid_601338 = query.getOrDefault("Action")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_601338 != nil:
    section.add "Action", valid_601338
  var valid_601339 = query.getOrDefault("ExpressionName")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = nil)
  if valid_601339 != nil:
    section.add "ExpressionName", valid_601339
  var valid_601340 = query.getOrDefault("DomainName")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = nil)
  if valid_601340 != nil:
    section.add "DomainName", valid_601340
  var valid_601341 = query.getOrDefault("Version")
  valid_601341 = validateParameter(valid_601341, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601341 != nil:
    section.add "Version", valid_601341
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
  var valid_601342 = header.getOrDefault("X-Amz-Date")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Date", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Security-Token")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Security-Token", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_GetDeleteExpression_601335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_GetDeleteExpression_601335; ExpressionName: string;
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
  var query_601351 = newJObject()
  add(query_601351, "Action", newJString(Action))
  add(query_601351, "ExpressionName", newJString(ExpressionName))
  add(query_601351, "DomainName", newJString(DomainName))
  add(query_601351, "Version", newJString(Version))
  result = call_601350.call(nil, query_601351, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_601335(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_601336, base: "/",
    url: url_GetDeleteExpression_601337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_601387 = ref object of OpenApiRestCall_600437
proc url_PostDeleteIndexField_601389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_601388(path: JsonNode; query: JsonNode;
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
  var valid_601390 = query.getOrDefault("Action")
  valid_601390 = validateParameter(valid_601390, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_601390 != nil:
    section.add "Action", valid_601390
  var valid_601391 = query.getOrDefault("Version")
  valid_601391 = validateParameter(valid_601391, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601391 != nil:
    section.add "Version", valid_601391
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
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601399 = formData.getOrDefault("DomainName")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = nil)
  if valid_601399 != nil:
    section.add "DomainName", valid_601399
  var valid_601400 = formData.getOrDefault("IndexFieldName")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "IndexFieldName", valid_601400
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601401: Call_PostDeleteIndexField_601387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601401.validator(path, query, header, formData, body)
  let scheme = call_601401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601401.url(scheme.get, call_601401.host, call_601401.base,
                         call_601401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601401, url, valid)

proc call*(call_601402: Call_PostDeleteIndexField_601387; DomainName: string;
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
  var query_601403 = newJObject()
  var formData_601404 = newJObject()
  add(formData_601404, "DomainName", newJString(DomainName))
  add(formData_601404, "IndexFieldName", newJString(IndexFieldName))
  add(query_601403, "Action", newJString(Action))
  add(query_601403, "Version", newJString(Version))
  result = call_601402.call(nil, query_601403, nil, formData_601404, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_601387(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_601388, base: "/",
    url: url_PostDeleteIndexField_601389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_601370 = ref object of OpenApiRestCall_600437
proc url_GetDeleteIndexField_601372(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_601371(path: JsonNode; query: JsonNode;
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
  var valid_601373 = query.getOrDefault("IndexFieldName")
  valid_601373 = validateParameter(valid_601373, JString, required = true,
                                 default = nil)
  if valid_601373 != nil:
    section.add "IndexFieldName", valid_601373
  var valid_601374 = query.getOrDefault("Action")
  valid_601374 = validateParameter(valid_601374, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_601374 != nil:
    section.add "Action", valid_601374
  var valid_601375 = query.getOrDefault("DomainName")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = nil)
  if valid_601375 != nil:
    section.add "DomainName", valid_601375
  var valid_601376 = query.getOrDefault("Version")
  valid_601376 = validateParameter(valid_601376, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601376 != nil:
    section.add "Version", valid_601376
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
  var valid_601377 = header.getOrDefault("X-Amz-Date")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Date", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Security-Token")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Security-Token", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_GetDeleteIndexField_601370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_GetDeleteIndexField_601370; IndexFieldName: string;
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
  var query_601386 = newJObject()
  add(query_601386, "IndexFieldName", newJString(IndexFieldName))
  add(query_601386, "Action", newJString(Action))
  add(query_601386, "DomainName", newJString(DomainName))
  add(query_601386, "Version", newJString(Version))
  result = call_601385.call(nil, query_601386, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_601370(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_601371, base: "/",
    url: url_GetDeleteIndexField_601372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_601422 = ref object of OpenApiRestCall_600437
proc url_PostDeleteSuggester_601424(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteSuggester_601423(path: JsonNode; query: JsonNode;
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
  var valid_601425 = query.getOrDefault("Action")
  valid_601425 = validateParameter(valid_601425, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_601425 != nil:
    section.add "Action", valid_601425
  var valid_601426 = query.getOrDefault("Version")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601426 != nil:
    section.add "Version", valid_601426
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
  var valid_601427 = header.getOrDefault("X-Amz-Date")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Date", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Security-Token")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Security-Token", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Content-Sha256", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Algorithm")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Algorithm", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Signature")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Signature", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-SignedHeaders", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Credential")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Credential", valid_601433
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601434 = formData.getOrDefault("DomainName")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = nil)
  if valid_601434 != nil:
    section.add "DomainName", valid_601434
  var valid_601435 = formData.getOrDefault("SuggesterName")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = nil)
  if valid_601435 != nil:
    section.add "SuggesterName", valid_601435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601436: Call_PostDeleteSuggester_601422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601436.validator(path, query, header, formData, body)
  let scheme = call_601436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601436.url(scheme.get, call_601436.host, call_601436.base,
                         call_601436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601436, url, valid)

proc call*(call_601437: Call_PostDeleteSuggester_601422; DomainName: string;
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
  var query_601438 = newJObject()
  var formData_601439 = newJObject()
  add(formData_601439, "DomainName", newJString(DomainName))
  add(query_601438, "Action", newJString(Action))
  add(formData_601439, "SuggesterName", newJString(SuggesterName))
  add(query_601438, "Version", newJString(Version))
  result = call_601437.call(nil, query_601438, nil, formData_601439, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_601422(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_601423, base: "/",
    url: url_PostDeleteSuggester_601424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_601405 = ref object of OpenApiRestCall_600437
proc url_GetDeleteSuggester_601407(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteSuggester_601406(path: JsonNode; query: JsonNode;
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
  var valid_601408 = query.getOrDefault("Action")
  valid_601408 = validateParameter(valid_601408, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_601408 != nil:
    section.add "Action", valid_601408
  var valid_601409 = query.getOrDefault("SuggesterName")
  valid_601409 = validateParameter(valid_601409, JString, required = true,
                                 default = nil)
  if valid_601409 != nil:
    section.add "SuggesterName", valid_601409
  var valid_601410 = query.getOrDefault("DomainName")
  valid_601410 = validateParameter(valid_601410, JString, required = true,
                                 default = nil)
  if valid_601410 != nil:
    section.add "DomainName", valid_601410
  var valid_601411 = query.getOrDefault("Version")
  valid_601411 = validateParameter(valid_601411, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601411 != nil:
    section.add "Version", valid_601411
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
  var valid_601412 = header.getOrDefault("X-Amz-Date")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Date", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Security-Token")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Security-Token", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Content-Sha256", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Algorithm")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Algorithm", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Signature")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Signature", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-SignedHeaders", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Credential")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Credential", valid_601418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601419: Call_GetDeleteSuggester_601405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601419.validator(path, query, header, formData, body)
  let scheme = call_601419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601419.url(scheme.get, call_601419.host, call_601419.base,
                         call_601419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601419, url, valid)

proc call*(call_601420: Call_GetDeleteSuggester_601405; SuggesterName: string;
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
  var query_601421 = newJObject()
  add(query_601421, "Action", newJString(Action))
  add(query_601421, "SuggesterName", newJString(SuggesterName))
  add(query_601421, "DomainName", newJString(DomainName))
  add(query_601421, "Version", newJString(Version))
  result = call_601420.call(nil, query_601421, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_601405(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_601406, base: "/",
    url: url_GetDeleteSuggester_601407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_601458 = ref object of OpenApiRestCall_600437
proc url_PostDescribeAnalysisSchemes_601460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnalysisSchemes_601459(path: JsonNode; query: JsonNode;
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
  var valid_601461 = query.getOrDefault("Action")
  valid_601461 = validateParameter(valid_601461, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_601461 != nil:
    section.add "Action", valid_601461
  var valid_601462 = query.getOrDefault("Version")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601462 != nil:
    section.add "Version", valid_601462
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
  var valid_601463 = header.getOrDefault("X-Amz-Date")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Date", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Security-Token")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Security-Token", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Content-Sha256", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Algorithm")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Algorithm", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Signature")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Signature", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-SignedHeaders", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Credential")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Credential", valid_601469
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
  var valid_601470 = formData.getOrDefault("DomainName")
  valid_601470 = validateParameter(valid_601470, JString, required = true,
                                 default = nil)
  if valid_601470 != nil:
    section.add "DomainName", valid_601470
  var valid_601471 = formData.getOrDefault("Deployed")
  valid_601471 = validateParameter(valid_601471, JBool, required = false, default = nil)
  if valid_601471 != nil:
    section.add "Deployed", valid_601471
  var valid_601472 = formData.getOrDefault("AnalysisSchemeNames")
  valid_601472 = validateParameter(valid_601472, JArray, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "AnalysisSchemeNames", valid_601472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601473: Call_PostDescribeAnalysisSchemes_601458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601473.validator(path, query, header, formData, body)
  let scheme = call_601473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601473.url(scheme.get, call_601473.host, call_601473.base,
                         call_601473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601473, url, valid)

proc call*(call_601474: Call_PostDescribeAnalysisSchemes_601458;
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
  var query_601475 = newJObject()
  var formData_601476 = newJObject()
  add(formData_601476, "DomainName", newJString(DomainName))
  add(formData_601476, "Deployed", newJBool(Deployed))
  add(query_601475, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_601476.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_601475, "Version", newJString(Version))
  result = call_601474.call(nil, query_601475, nil, formData_601476, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_601458(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_601459, base: "/",
    url: url_PostDescribeAnalysisSchemes_601460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_601440 = ref object of OpenApiRestCall_600437
proc url_GetDescribeAnalysisSchemes_601442(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnalysisSchemes_601441(path: JsonNode; query: JsonNode;
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
  var valid_601443 = query.getOrDefault("Deployed")
  valid_601443 = validateParameter(valid_601443, JBool, required = false, default = nil)
  if valid_601443 != nil:
    section.add "Deployed", valid_601443
  var valid_601444 = query.getOrDefault("AnalysisSchemeNames")
  valid_601444 = validateParameter(valid_601444, JArray, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "AnalysisSchemeNames", valid_601444
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601445 = query.getOrDefault("Action")
  valid_601445 = validateParameter(valid_601445, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_601445 != nil:
    section.add "Action", valid_601445
  var valid_601446 = query.getOrDefault("DomainName")
  valid_601446 = validateParameter(valid_601446, JString, required = true,
                                 default = nil)
  if valid_601446 != nil:
    section.add "DomainName", valid_601446
  var valid_601447 = query.getOrDefault("Version")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601447 != nil:
    section.add "Version", valid_601447
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
  var valid_601448 = header.getOrDefault("X-Amz-Date")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Date", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Security-Token")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Security-Token", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Content-Sha256", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Algorithm")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Algorithm", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Signature")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Signature", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-SignedHeaders", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Credential")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Credential", valid_601454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601455: Call_GetDescribeAnalysisSchemes_601440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601455.validator(path, query, header, formData, body)
  let scheme = call_601455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601455.url(scheme.get, call_601455.host, call_601455.base,
                         call_601455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601455, url, valid)

proc call*(call_601456: Call_GetDescribeAnalysisSchemes_601440; DomainName: string;
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
  var query_601457 = newJObject()
  add(query_601457, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_601457.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_601457, "Action", newJString(Action))
  add(query_601457, "DomainName", newJString(DomainName))
  add(query_601457, "Version", newJString(Version))
  result = call_601456.call(nil, query_601457, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_601440(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_601441, base: "/",
    url: url_GetDescribeAnalysisSchemes_601442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_601494 = ref object of OpenApiRestCall_600437
proc url_PostDescribeAvailabilityOptions_601496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_601495(path: JsonNode;
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
  var valid_601497 = query.getOrDefault("Action")
  valid_601497 = validateParameter(valid_601497, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_601497 != nil:
    section.add "Action", valid_601497
  var valid_601498 = query.getOrDefault("Version")
  valid_601498 = validateParameter(valid_601498, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601498 != nil:
    section.add "Version", valid_601498
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
  var valid_601499 = header.getOrDefault("X-Amz-Date")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Date", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Security-Token")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Security-Token", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Content-Sha256", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Algorithm")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Algorithm", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Signature")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Signature", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-SignedHeaders", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Credential")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Credential", valid_601505
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601506 = formData.getOrDefault("DomainName")
  valid_601506 = validateParameter(valid_601506, JString, required = true,
                                 default = nil)
  if valid_601506 != nil:
    section.add "DomainName", valid_601506
  var valid_601507 = formData.getOrDefault("Deployed")
  valid_601507 = validateParameter(valid_601507, JBool, required = false, default = nil)
  if valid_601507 != nil:
    section.add "Deployed", valid_601507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601508: Call_PostDescribeAvailabilityOptions_601494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601508.validator(path, query, header, formData, body)
  let scheme = call_601508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601508.url(scheme.get, call_601508.host, call_601508.base,
                         call_601508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601508, url, valid)

proc call*(call_601509: Call_PostDescribeAvailabilityOptions_601494;
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
  var query_601510 = newJObject()
  var formData_601511 = newJObject()
  add(formData_601511, "DomainName", newJString(DomainName))
  add(formData_601511, "Deployed", newJBool(Deployed))
  add(query_601510, "Action", newJString(Action))
  add(query_601510, "Version", newJString(Version))
  result = call_601509.call(nil, query_601510, nil, formData_601511, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_601494(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_601495, base: "/",
    url: url_PostDescribeAvailabilityOptions_601496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_601477 = ref object of OpenApiRestCall_600437
proc url_GetDescribeAvailabilityOptions_601479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_601478(path: JsonNode;
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
  var valid_601480 = query.getOrDefault("Deployed")
  valid_601480 = validateParameter(valid_601480, JBool, required = false, default = nil)
  if valid_601480 != nil:
    section.add "Deployed", valid_601480
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601481 = query.getOrDefault("Action")
  valid_601481 = validateParameter(valid_601481, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_601481 != nil:
    section.add "Action", valid_601481
  var valid_601482 = query.getOrDefault("DomainName")
  valid_601482 = validateParameter(valid_601482, JString, required = true,
                                 default = nil)
  if valid_601482 != nil:
    section.add "DomainName", valid_601482
  var valid_601483 = query.getOrDefault("Version")
  valid_601483 = validateParameter(valid_601483, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601483 != nil:
    section.add "Version", valid_601483
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
  var valid_601484 = header.getOrDefault("X-Amz-Date")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Date", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Security-Token")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Security-Token", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Content-Sha256", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Algorithm")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Algorithm", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Signature")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Signature", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-SignedHeaders", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Credential")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Credential", valid_601490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_GetDescribeAvailabilityOptions_601477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_GetDescribeAvailabilityOptions_601477;
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
  var query_601493 = newJObject()
  add(query_601493, "Deployed", newJBool(Deployed))
  add(query_601493, "Action", newJString(Action))
  add(query_601493, "DomainName", newJString(DomainName))
  add(query_601493, "Version", newJString(Version))
  result = call_601492.call(nil, query_601493, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_601477(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_601478, base: "/",
    url: url_GetDescribeAvailabilityOptions_601479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_601528 = ref object of OpenApiRestCall_600437
proc url_PostDescribeDomains_601530(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_601529(path: JsonNode; query: JsonNode;
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
  var valid_601531 = query.getOrDefault("Action")
  valid_601531 = validateParameter(valid_601531, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_601531 != nil:
    section.add "Action", valid_601531
  var valid_601532 = query.getOrDefault("Version")
  valid_601532 = validateParameter(valid_601532, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601532 != nil:
    section.add "Version", valid_601532
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
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Content-Sha256", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Algorithm")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Algorithm", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Signature")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Signature", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-SignedHeaders", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Credential")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Credential", valid_601539
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_601540 = formData.getOrDefault("DomainNames")
  valid_601540 = validateParameter(valid_601540, JArray, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "DomainNames", valid_601540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601541: Call_PostDescribeDomains_601528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601541.validator(path, query, header, formData, body)
  let scheme = call_601541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601541.url(scheme.get, call_601541.host, call_601541.base,
                         call_601541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601541, url, valid)

proc call*(call_601542: Call_PostDescribeDomains_601528;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601543 = newJObject()
  var formData_601544 = newJObject()
  if DomainNames != nil:
    formData_601544.add "DomainNames", DomainNames
  add(query_601543, "Action", newJString(Action))
  add(query_601543, "Version", newJString(Version))
  result = call_601542.call(nil, query_601543, nil, formData_601544, nil)

var postDescribeDomains* = Call_PostDescribeDomains_601528(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_601529, base: "/",
    url: url_PostDescribeDomains_601530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_601512 = ref object of OpenApiRestCall_600437
proc url_GetDescribeDomains_601514(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_601513(path: JsonNode; query: JsonNode;
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
  var valid_601515 = query.getOrDefault("DomainNames")
  valid_601515 = validateParameter(valid_601515, JArray, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "DomainNames", valid_601515
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601516 = query.getOrDefault("Action")
  valid_601516 = validateParameter(valid_601516, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_601516 != nil:
    section.add "Action", valid_601516
  var valid_601517 = query.getOrDefault("Version")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601517 != nil:
    section.add "Version", valid_601517
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
  var valid_601518 = header.getOrDefault("X-Amz-Date")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Date", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Security-Token")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Security-Token", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Content-Sha256", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Algorithm")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Algorithm", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Signature")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Signature", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-SignedHeaders", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Credential")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Credential", valid_601524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601525: Call_GetDescribeDomains_601512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601525.validator(path, query, header, formData, body)
  let scheme = call_601525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601525.url(scheme.get, call_601525.host, call_601525.base,
                         call_601525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601525, url, valid)

proc call*(call_601526: Call_GetDescribeDomains_601512;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601527 = newJObject()
  if DomainNames != nil:
    query_601527.add "DomainNames", DomainNames
  add(query_601527, "Action", newJString(Action))
  add(query_601527, "Version", newJString(Version))
  result = call_601526.call(nil, query_601527, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_601512(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_601513, base: "/",
    url: url_GetDescribeDomains_601514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_601563 = ref object of OpenApiRestCall_600437
proc url_PostDescribeExpressions_601565(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeExpressions_601564(path: JsonNode; query: JsonNode;
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
  var valid_601566 = query.getOrDefault("Action")
  valid_601566 = validateParameter(valid_601566, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_601566 != nil:
    section.add "Action", valid_601566
  var valid_601567 = query.getOrDefault("Version")
  valid_601567 = validateParameter(valid_601567, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601567 != nil:
    section.add "Version", valid_601567
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
  var valid_601568 = header.getOrDefault("X-Amz-Date")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Date", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Security-Token")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Security-Token", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Content-Sha256", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Algorithm")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Algorithm", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Signature")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Signature", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-SignedHeaders", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Credential")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Credential", valid_601574
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
  var valid_601575 = formData.getOrDefault("DomainName")
  valid_601575 = validateParameter(valid_601575, JString, required = true,
                                 default = nil)
  if valid_601575 != nil:
    section.add "DomainName", valid_601575
  var valid_601576 = formData.getOrDefault("Deployed")
  valid_601576 = validateParameter(valid_601576, JBool, required = false, default = nil)
  if valid_601576 != nil:
    section.add "Deployed", valid_601576
  var valid_601577 = formData.getOrDefault("ExpressionNames")
  valid_601577 = validateParameter(valid_601577, JArray, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "ExpressionNames", valid_601577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601578: Call_PostDescribeExpressions_601563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601578.validator(path, query, header, formData, body)
  let scheme = call_601578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601578.url(scheme.get, call_601578.host, call_601578.base,
                         call_601578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601578, url, valid)

proc call*(call_601579: Call_PostDescribeExpressions_601563; DomainName: string;
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
  var query_601580 = newJObject()
  var formData_601581 = newJObject()
  add(formData_601581, "DomainName", newJString(DomainName))
  add(formData_601581, "Deployed", newJBool(Deployed))
  add(query_601580, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_601581.add "ExpressionNames", ExpressionNames
  add(query_601580, "Version", newJString(Version))
  result = call_601579.call(nil, query_601580, nil, formData_601581, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_601563(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_601564, base: "/",
    url: url_PostDescribeExpressions_601565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_601545 = ref object of OpenApiRestCall_600437
proc url_GetDescribeExpressions_601547(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeExpressions_601546(path: JsonNode; query: JsonNode;
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
  var valid_601548 = query.getOrDefault("Deployed")
  valid_601548 = validateParameter(valid_601548, JBool, required = false, default = nil)
  if valid_601548 != nil:
    section.add "Deployed", valid_601548
  var valid_601549 = query.getOrDefault("ExpressionNames")
  valid_601549 = validateParameter(valid_601549, JArray, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "ExpressionNames", valid_601549
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601550 = query.getOrDefault("Action")
  valid_601550 = validateParameter(valid_601550, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_601550 != nil:
    section.add "Action", valid_601550
  var valid_601551 = query.getOrDefault("DomainName")
  valid_601551 = validateParameter(valid_601551, JString, required = true,
                                 default = nil)
  if valid_601551 != nil:
    section.add "DomainName", valid_601551
  var valid_601552 = query.getOrDefault("Version")
  valid_601552 = validateParameter(valid_601552, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601552 != nil:
    section.add "Version", valid_601552
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
  var valid_601553 = header.getOrDefault("X-Amz-Date")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Date", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Security-Token")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Security-Token", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Content-Sha256", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Algorithm")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Algorithm", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Signature")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Signature", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-SignedHeaders", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Credential")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Credential", valid_601559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601560: Call_GetDescribeExpressions_601545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601560.validator(path, query, header, formData, body)
  let scheme = call_601560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601560.url(scheme.get, call_601560.host, call_601560.base,
                         call_601560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601560, url, valid)

proc call*(call_601561: Call_GetDescribeExpressions_601545; DomainName: string;
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
  var query_601562 = newJObject()
  add(query_601562, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_601562.add "ExpressionNames", ExpressionNames
  add(query_601562, "Action", newJString(Action))
  add(query_601562, "DomainName", newJString(DomainName))
  add(query_601562, "Version", newJString(Version))
  result = call_601561.call(nil, query_601562, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_601545(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_601546, base: "/",
    url: url_GetDescribeExpressions_601547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_601600 = ref object of OpenApiRestCall_600437
proc url_PostDescribeIndexFields_601602(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_601601(path: JsonNode; query: JsonNode;
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
  var valid_601603 = query.getOrDefault("Action")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_601603 != nil:
    section.add "Action", valid_601603
  var valid_601604 = query.getOrDefault("Version")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601604 != nil:
    section.add "Version", valid_601604
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
  var valid_601605 = header.getOrDefault("X-Amz-Date")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Date", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Security-Token")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Security-Token", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Content-Sha256", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Algorithm")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Algorithm", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Signature")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Signature", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-SignedHeaders", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Credential")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Credential", valid_601611
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
  var valid_601612 = formData.getOrDefault("DomainName")
  valid_601612 = validateParameter(valid_601612, JString, required = true,
                                 default = nil)
  if valid_601612 != nil:
    section.add "DomainName", valid_601612
  var valid_601613 = formData.getOrDefault("Deployed")
  valid_601613 = validateParameter(valid_601613, JBool, required = false, default = nil)
  if valid_601613 != nil:
    section.add "Deployed", valid_601613
  var valid_601614 = formData.getOrDefault("FieldNames")
  valid_601614 = validateParameter(valid_601614, JArray, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "FieldNames", valid_601614
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601615: Call_PostDescribeIndexFields_601600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601615.validator(path, query, header, formData, body)
  let scheme = call_601615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601615.url(scheme.get, call_601615.host, call_601615.base,
                         call_601615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601615, url, valid)

proc call*(call_601616: Call_PostDescribeIndexFields_601600; DomainName: string;
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
  var query_601617 = newJObject()
  var formData_601618 = newJObject()
  add(formData_601618, "DomainName", newJString(DomainName))
  add(formData_601618, "Deployed", newJBool(Deployed))
  add(query_601617, "Action", newJString(Action))
  if FieldNames != nil:
    formData_601618.add "FieldNames", FieldNames
  add(query_601617, "Version", newJString(Version))
  result = call_601616.call(nil, query_601617, nil, formData_601618, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_601600(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_601601, base: "/",
    url: url_PostDescribeIndexFields_601602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_601582 = ref object of OpenApiRestCall_600437
proc url_GetDescribeIndexFields_601584(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_601583(path: JsonNode; query: JsonNode;
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
  var valid_601585 = query.getOrDefault("Deployed")
  valid_601585 = validateParameter(valid_601585, JBool, required = false, default = nil)
  if valid_601585 != nil:
    section.add "Deployed", valid_601585
  var valid_601586 = query.getOrDefault("FieldNames")
  valid_601586 = validateParameter(valid_601586, JArray, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "FieldNames", valid_601586
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601587 = query.getOrDefault("Action")
  valid_601587 = validateParameter(valid_601587, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_601587 != nil:
    section.add "Action", valid_601587
  var valid_601588 = query.getOrDefault("DomainName")
  valid_601588 = validateParameter(valid_601588, JString, required = true,
                                 default = nil)
  if valid_601588 != nil:
    section.add "DomainName", valid_601588
  var valid_601589 = query.getOrDefault("Version")
  valid_601589 = validateParameter(valid_601589, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601589 != nil:
    section.add "Version", valid_601589
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
  var valid_601590 = header.getOrDefault("X-Amz-Date")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Date", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Security-Token")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Security-Token", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Content-Sha256", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Algorithm")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Algorithm", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Signature")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Signature", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-SignedHeaders", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Credential")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Credential", valid_601596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601597: Call_GetDescribeIndexFields_601582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601597.validator(path, query, header, formData, body)
  let scheme = call_601597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601597.url(scheme.get, call_601597.host, call_601597.base,
                         call_601597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601597, url, valid)

proc call*(call_601598: Call_GetDescribeIndexFields_601582; DomainName: string;
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
  var query_601599 = newJObject()
  add(query_601599, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_601599.add "FieldNames", FieldNames
  add(query_601599, "Action", newJString(Action))
  add(query_601599, "DomainName", newJString(DomainName))
  add(query_601599, "Version", newJString(Version))
  result = call_601598.call(nil, query_601599, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_601582(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_601583, base: "/",
    url: url_GetDescribeIndexFields_601584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_601635 = ref object of OpenApiRestCall_600437
proc url_PostDescribeScalingParameters_601637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeScalingParameters_601636(path: JsonNode; query: JsonNode;
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
  var valid_601638 = query.getOrDefault("Action")
  valid_601638 = validateParameter(valid_601638, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_601638 != nil:
    section.add "Action", valid_601638
  var valid_601639 = query.getOrDefault("Version")
  valid_601639 = validateParameter(valid_601639, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601639 != nil:
    section.add "Version", valid_601639
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
  var valid_601640 = header.getOrDefault("X-Amz-Date")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Date", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Security-Token")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Security-Token", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Content-Sha256", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Algorithm")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Algorithm", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-Signature")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Signature", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-SignedHeaders", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Credential")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Credential", valid_601646
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601647 = formData.getOrDefault("DomainName")
  valid_601647 = validateParameter(valid_601647, JString, required = true,
                                 default = nil)
  if valid_601647 != nil:
    section.add "DomainName", valid_601647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601648: Call_PostDescribeScalingParameters_601635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601648.validator(path, query, header, formData, body)
  let scheme = call_601648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601648.url(scheme.get, call_601648.host, call_601648.base,
                         call_601648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601648, url, valid)

proc call*(call_601649: Call_PostDescribeScalingParameters_601635;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601650 = newJObject()
  var formData_601651 = newJObject()
  add(formData_601651, "DomainName", newJString(DomainName))
  add(query_601650, "Action", newJString(Action))
  add(query_601650, "Version", newJString(Version))
  result = call_601649.call(nil, query_601650, nil, formData_601651, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_601635(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_601636, base: "/",
    url: url_PostDescribeScalingParameters_601637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_601619 = ref object of OpenApiRestCall_600437
proc url_GetDescribeScalingParameters_601621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeScalingParameters_601620(path: JsonNode; query: JsonNode;
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
  var valid_601622 = query.getOrDefault("Action")
  valid_601622 = validateParameter(valid_601622, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_601622 != nil:
    section.add "Action", valid_601622
  var valid_601623 = query.getOrDefault("DomainName")
  valid_601623 = validateParameter(valid_601623, JString, required = true,
                                 default = nil)
  if valid_601623 != nil:
    section.add "DomainName", valid_601623
  var valid_601624 = query.getOrDefault("Version")
  valid_601624 = validateParameter(valid_601624, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601624 != nil:
    section.add "Version", valid_601624
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
  var valid_601625 = header.getOrDefault("X-Amz-Date")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Date", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Security-Token")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Security-Token", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Content-Sha256", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Algorithm")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Algorithm", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Signature")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Signature", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-SignedHeaders", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Credential")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Credential", valid_601631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601632: Call_GetDescribeScalingParameters_601619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601632.validator(path, query, header, formData, body)
  let scheme = call_601632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601632.url(scheme.get, call_601632.host, call_601632.base,
                         call_601632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601632, url, valid)

proc call*(call_601633: Call_GetDescribeScalingParameters_601619;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_601634 = newJObject()
  add(query_601634, "Action", newJString(Action))
  add(query_601634, "DomainName", newJString(DomainName))
  add(query_601634, "Version", newJString(Version))
  result = call_601633.call(nil, query_601634, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_601619(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_601620, base: "/",
    url: url_GetDescribeScalingParameters_601621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_601669 = ref object of OpenApiRestCall_600437
proc url_PostDescribeServiceAccessPolicies_601671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_601670(path: JsonNode;
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
  var valid_601672 = query.getOrDefault("Action")
  valid_601672 = validateParameter(valid_601672, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_601672 != nil:
    section.add "Action", valid_601672
  var valid_601673 = query.getOrDefault("Version")
  valid_601673 = validateParameter(valid_601673, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601673 != nil:
    section.add "Version", valid_601673
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
  var valid_601674 = header.getOrDefault("X-Amz-Date")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Date", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Security-Token")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Security-Token", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Content-Sha256", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Algorithm")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Algorithm", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Signature")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Signature", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-SignedHeaders", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Credential")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Credential", valid_601680
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601681 = formData.getOrDefault("DomainName")
  valid_601681 = validateParameter(valid_601681, JString, required = true,
                                 default = nil)
  if valid_601681 != nil:
    section.add "DomainName", valid_601681
  var valid_601682 = formData.getOrDefault("Deployed")
  valid_601682 = validateParameter(valid_601682, JBool, required = false, default = nil)
  if valid_601682 != nil:
    section.add "Deployed", valid_601682
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601683: Call_PostDescribeServiceAccessPolicies_601669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601683.validator(path, query, header, formData, body)
  let scheme = call_601683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601683.url(scheme.get, call_601683.host, call_601683.base,
                         call_601683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601683, url, valid)

proc call*(call_601684: Call_PostDescribeServiceAccessPolicies_601669;
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
  var query_601685 = newJObject()
  var formData_601686 = newJObject()
  add(formData_601686, "DomainName", newJString(DomainName))
  add(formData_601686, "Deployed", newJBool(Deployed))
  add(query_601685, "Action", newJString(Action))
  add(query_601685, "Version", newJString(Version))
  result = call_601684.call(nil, query_601685, nil, formData_601686, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_601669(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_601670, base: "/",
    url: url_PostDescribeServiceAccessPolicies_601671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_601652 = ref object of OpenApiRestCall_600437
proc url_GetDescribeServiceAccessPolicies_601654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_601653(path: JsonNode;
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
  var valid_601655 = query.getOrDefault("Deployed")
  valid_601655 = validateParameter(valid_601655, JBool, required = false, default = nil)
  if valid_601655 != nil:
    section.add "Deployed", valid_601655
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601656 = query.getOrDefault("Action")
  valid_601656 = validateParameter(valid_601656, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_601656 != nil:
    section.add "Action", valid_601656
  var valid_601657 = query.getOrDefault("DomainName")
  valid_601657 = validateParameter(valid_601657, JString, required = true,
                                 default = nil)
  if valid_601657 != nil:
    section.add "DomainName", valid_601657
  var valid_601658 = query.getOrDefault("Version")
  valid_601658 = validateParameter(valid_601658, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601658 != nil:
    section.add "Version", valid_601658
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
  var valid_601659 = header.getOrDefault("X-Amz-Date")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Date", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Security-Token")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Security-Token", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Content-Sha256", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Algorithm")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Algorithm", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Signature")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Signature", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-SignedHeaders", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Credential")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Credential", valid_601665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601666: Call_GetDescribeServiceAccessPolicies_601652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601666.validator(path, query, header, formData, body)
  let scheme = call_601666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601666.url(scheme.get, call_601666.host, call_601666.base,
                         call_601666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601666, url, valid)

proc call*(call_601667: Call_GetDescribeServiceAccessPolicies_601652;
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
  var query_601668 = newJObject()
  add(query_601668, "Deployed", newJBool(Deployed))
  add(query_601668, "Action", newJString(Action))
  add(query_601668, "DomainName", newJString(DomainName))
  add(query_601668, "Version", newJString(Version))
  result = call_601667.call(nil, query_601668, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_601652(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_601653, base: "/",
    url: url_GetDescribeServiceAccessPolicies_601654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_601705 = ref object of OpenApiRestCall_600437
proc url_PostDescribeSuggesters_601707(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSuggesters_601706(path: JsonNode; query: JsonNode;
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
  var valid_601708 = query.getOrDefault("Action")
  valid_601708 = validateParameter(valid_601708, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_601708 != nil:
    section.add "Action", valid_601708
  var valid_601709 = query.getOrDefault("Version")
  valid_601709 = validateParameter(valid_601709, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601709 != nil:
    section.add "Version", valid_601709
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
  var valid_601710 = header.getOrDefault("X-Amz-Date")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Date", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Security-Token")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Security-Token", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Content-Sha256", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Algorithm")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Algorithm", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Signature")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Signature", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-SignedHeaders", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Credential")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Credential", valid_601716
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
  var valid_601717 = formData.getOrDefault("DomainName")
  valid_601717 = validateParameter(valid_601717, JString, required = true,
                                 default = nil)
  if valid_601717 != nil:
    section.add "DomainName", valid_601717
  var valid_601718 = formData.getOrDefault("Deployed")
  valid_601718 = validateParameter(valid_601718, JBool, required = false, default = nil)
  if valid_601718 != nil:
    section.add "Deployed", valid_601718
  var valid_601719 = formData.getOrDefault("SuggesterNames")
  valid_601719 = validateParameter(valid_601719, JArray, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "SuggesterNames", valid_601719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601720: Call_PostDescribeSuggesters_601705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601720.validator(path, query, header, formData, body)
  let scheme = call_601720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601720.url(scheme.get, call_601720.host, call_601720.base,
                         call_601720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601720, url, valid)

proc call*(call_601721: Call_PostDescribeSuggesters_601705; DomainName: string;
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
  var query_601722 = newJObject()
  var formData_601723 = newJObject()
  add(formData_601723, "DomainName", newJString(DomainName))
  add(formData_601723, "Deployed", newJBool(Deployed))
  add(query_601722, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_601723.add "SuggesterNames", SuggesterNames
  add(query_601722, "Version", newJString(Version))
  result = call_601721.call(nil, query_601722, nil, formData_601723, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_601705(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_601706, base: "/",
    url: url_PostDescribeSuggesters_601707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_601687 = ref object of OpenApiRestCall_600437
proc url_GetDescribeSuggesters_601689(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSuggesters_601688(path: JsonNode; query: JsonNode;
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
  var valid_601690 = query.getOrDefault("Deployed")
  valid_601690 = validateParameter(valid_601690, JBool, required = false, default = nil)
  if valid_601690 != nil:
    section.add "Deployed", valid_601690
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601691 = query.getOrDefault("Action")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_601691 != nil:
    section.add "Action", valid_601691
  var valid_601692 = query.getOrDefault("DomainName")
  valid_601692 = validateParameter(valid_601692, JString, required = true,
                                 default = nil)
  if valid_601692 != nil:
    section.add "DomainName", valid_601692
  var valid_601693 = query.getOrDefault("Version")
  valid_601693 = validateParameter(valid_601693, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601693 != nil:
    section.add "Version", valid_601693
  var valid_601694 = query.getOrDefault("SuggesterNames")
  valid_601694 = validateParameter(valid_601694, JArray, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "SuggesterNames", valid_601694
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
  var valid_601695 = header.getOrDefault("X-Amz-Date")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Date", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Security-Token")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Security-Token", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Content-Sha256", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Algorithm")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Algorithm", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Signature")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Signature", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-SignedHeaders", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Credential")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Credential", valid_601701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601702: Call_GetDescribeSuggesters_601687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601702.validator(path, query, header, formData, body)
  let scheme = call_601702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601702.url(scheme.get, call_601702.host, call_601702.base,
                         call_601702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601702, url, valid)

proc call*(call_601703: Call_GetDescribeSuggesters_601687; DomainName: string;
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
  var query_601704 = newJObject()
  add(query_601704, "Deployed", newJBool(Deployed))
  add(query_601704, "Action", newJString(Action))
  add(query_601704, "DomainName", newJString(DomainName))
  add(query_601704, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_601704.add "SuggesterNames", SuggesterNames
  result = call_601703.call(nil, query_601704, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_601687(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_601688, base: "/",
    url: url_GetDescribeSuggesters_601689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_601740 = ref object of OpenApiRestCall_600437
proc url_PostIndexDocuments_601742(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_601741(path: JsonNode; query: JsonNode;
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
  var valid_601743 = query.getOrDefault("Action")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_601743 != nil:
    section.add "Action", valid_601743
  var valid_601744 = query.getOrDefault("Version")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601744 != nil:
    section.add "Version", valid_601744
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
  var valid_601745 = header.getOrDefault("X-Amz-Date")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Date", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Security-Token")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Security-Token", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Content-Sha256", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Algorithm")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Algorithm", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Signature")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Signature", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-SignedHeaders", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Credential")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Credential", valid_601751
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601752 = formData.getOrDefault("DomainName")
  valid_601752 = validateParameter(valid_601752, JString, required = true,
                                 default = nil)
  if valid_601752 != nil:
    section.add "DomainName", valid_601752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601753: Call_PostIndexDocuments_601740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_601753.validator(path, query, header, formData, body)
  let scheme = call_601753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601753.url(scheme.get, call_601753.host, call_601753.base,
                         call_601753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601753, url, valid)

proc call*(call_601754: Call_PostIndexDocuments_601740; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601755 = newJObject()
  var formData_601756 = newJObject()
  add(formData_601756, "DomainName", newJString(DomainName))
  add(query_601755, "Action", newJString(Action))
  add(query_601755, "Version", newJString(Version))
  result = call_601754.call(nil, query_601755, nil, formData_601756, nil)

var postIndexDocuments* = Call_PostIndexDocuments_601740(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_601741, base: "/",
    url: url_PostIndexDocuments_601742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_601724 = ref object of OpenApiRestCall_600437
proc url_GetIndexDocuments_601726(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_601725(path: JsonNode; query: JsonNode;
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
  var valid_601727 = query.getOrDefault("Action")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_601727 != nil:
    section.add "Action", valid_601727
  var valid_601728 = query.getOrDefault("DomainName")
  valid_601728 = validateParameter(valid_601728, JString, required = true,
                                 default = nil)
  if valid_601728 != nil:
    section.add "DomainName", valid_601728
  var valid_601729 = query.getOrDefault("Version")
  valid_601729 = validateParameter(valid_601729, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601729 != nil:
    section.add "Version", valid_601729
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
  var valid_601730 = header.getOrDefault("X-Amz-Date")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Date", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Security-Token")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Security-Token", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Content-Sha256", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Algorithm")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Algorithm", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Signature")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Signature", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-SignedHeaders", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Credential")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Credential", valid_601736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601737: Call_GetIndexDocuments_601724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_601737.validator(path, query, header, formData, body)
  let scheme = call_601737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601737.url(scheme.get, call_601737.host, call_601737.base,
                         call_601737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601737, url, valid)

proc call*(call_601738: Call_GetIndexDocuments_601724; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_601739 = newJObject()
  add(query_601739, "Action", newJString(Action))
  add(query_601739, "DomainName", newJString(DomainName))
  add(query_601739, "Version", newJString(Version))
  result = call_601738.call(nil, query_601739, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_601724(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_601725,
    base: "/", url: url_GetIndexDocuments_601726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_601772 = ref object of OpenApiRestCall_600437
proc url_PostListDomainNames_601774(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomainNames_601773(path: JsonNode; query: JsonNode;
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
  var valid_601775 = query.getOrDefault("Action")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_601775 != nil:
    section.add "Action", valid_601775
  var valid_601776 = query.getOrDefault("Version")
  valid_601776 = validateParameter(valid_601776, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601776 != nil:
    section.add "Version", valid_601776
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
  var valid_601777 = header.getOrDefault("X-Amz-Date")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Date", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Security-Token")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Security-Token", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Content-Sha256", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Algorithm")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Algorithm", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Signature")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Signature", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-SignedHeaders", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Credential")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Credential", valid_601783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601784: Call_PostListDomainNames_601772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_601784.validator(path, query, header, formData, body)
  let scheme = call_601784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601784.url(scheme.get, call_601784.host, call_601784.base,
                         call_601784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601784, url, valid)

proc call*(call_601785: Call_PostListDomainNames_601772;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601786 = newJObject()
  add(query_601786, "Action", newJString(Action))
  add(query_601786, "Version", newJString(Version))
  result = call_601785.call(nil, query_601786, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_601772(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_601773, base: "/",
    url: url_PostListDomainNames_601774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_601757 = ref object of OpenApiRestCall_600437
proc url_GetListDomainNames_601759(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomainNames_601758(path: JsonNode; query: JsonNode;
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
  var valid_601760 = query.getOrDefault("Action")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_601760 != nil:
    section.add "Action", valid_601760
  var valid_601761 = query.getOrDefault("Version")
  valid_601761 = validateParameter(valid_601761, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601761 != nil:
    section.add "Version", valid_601761
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
  var valid_601762 = header.getOrDefault("X-Amz-Date")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Date", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Security-Token")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Security-Token", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Content-Sha256", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Algorithm")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Algorithm", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Signature")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Signature", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-SignedHeaders", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Credential")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Credential", valid_601768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601769: Call_GetListDomainNames_601757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_601769.validator(path, query, header, formData, body)
  let scheme = call_601769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601769.url(scheme.get, call_601769.host, call_601769.base,
                         call_601769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601769, url, valid)

proc call*(call_601770: Call_GetListDomainNames_601757;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601771 = newJObject()
  add(query_601771, "Action", newJString(Action))
  add(query_601771, "Version", newJString(Version))
  result = call_601770.call(nil, query_601771, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_601757(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_601758, base: "/",
    url: url_GetListDomainNames_601759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_601804 = ref object of OpenApiRestCall_600437
proc url_PostUpdateAvailabilityOptions_601806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_601805(path: JsonNode; query: JsonNode;
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
  var valid_601807 = query.getOrDefault("Action")
  valid_601807 = validateParameter(valid_601807, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_601807 != nil:
    section.add "Action", valid_601807
  var valid_601808 = query.getOrDefault("Version")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601808 != nil:
    section.add "Version", valid_601808
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
  var valid_601809 = header.getOrDefault("X-Amz-Date")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Date", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Security-Token")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Security-Token", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Content-Sha256", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Algorithm")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Algorithm", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Signature")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Signature", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-SignedHeaders", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Credential")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Credential", valid_601815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601816 = formData.getOrDefault("DomainName")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = nil)
  if valid_601816 != nil:
    section.add "DomainName", valid_601816
  var valid_601817 = formData.getOrDefault("MultiAZ")
  valid_601817 = validateParameter(valid_601817, JBool, required = true, default = nil)
  if valid_601817 != nil:
    section.add "MultiAZ", valid_601817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601818: Call_PostUpdateAvailabilityOptions_601804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601818.validator(path, query, header, formData, body)
  let scheme = call_601818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601818.url(scheme.get, call_601818.host, call_601818.base,
                         call_601818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601818, url, valid)

proc call*(call_601819: Call_PostUpdateAvailabilityOptions_601804;
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
  var query_601820 = newJObject()
  var formData_601821 = newJObject()
  add(formData_601821, "DomainName", newJString(DomainName))
  add(formData_601821, "MultiAZ", newJBool(MultiAZ))
  add(query_601820, "Action", newJString(Action))
  add(query_601820, "Version", newJString(Version))
  result = call_601819.call(nil, query_601820, nil, formData_601821, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_601804(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_601805, base: "/",
    url: url_PostUpdateAvailabilityOptions_601806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_601787 = ref object of OpenApiRestCall_600437
proc url_GetUpdateAvailabilityOptions_601789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_601788(path: JsonNode; query: JsonNode;
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
  var valid_601790 = query.getOrDefault("MultiAZ")
  valid_601790 = validateParameter(valid_601790, JBool, required = true, default = nil)
  if valid_601790 != nil:
    section.add "MultiAZ", valid_601790
  var valid_601791 = query.getOrDefault("Action")
  valid_601791 = validateParameter(valid_601791, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_601791 != nil:
    section.add "Action", valid_601791
  var valid_601792 = query.getOrDefault("DomainName")
  valid_601792 = validateParameter(valid_601792, JString, required = true,
                                 default = nil)
  if valid_601792 != nil:
    section.add "DomainName", valid_601792
  var valid_601793 = query.getOrDefault("Version")
  valid_601793 = validateParameter(valid_601793, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601793 != nil:
    section.add "Version", valid_601793
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
  var valid_601794 = header.getOrDefault("X-Amz-Date")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Date", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Security-Token")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Security-Token", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Content-Sha256", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Algorithm")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Algorithm", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Signature")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Signature", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-SignedHeaders", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Credential")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Credential", valid_601800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601801: Call_GetUpdateAvailabilityOptions_601787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601801.validator(path, query, header, formData, body)
  let scheme = call_601801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601801.url(scheme.get, call_601801.host, call_601801.base,
                         call_601801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601801, url, valid)

proc call*(call_601802: Call_GetUpdateAvailabilityOptions_601787; MultiAZ: bool;
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
  var query_601803 = newJObject()
  add(query_601803, "MultiAZ", newJBool(MultiAZ))
  add(query_601803, "Action", newJString(Action))
  add(query_601803, "DomainName", newJString(DomainName))
  add(query_601803, "Version", newJString(Version))
  result = call_601802.call(nil, query_601803, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_601787(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_601788, base: "/",
    url: url_GetUpdateAvailabilityOptions_601789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_601841 = ref object of OpenApiRestCall_600437
proc url_PostUpdateScalingParameters_601843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateScalingParameters_601842(path: JsonNode; query: JsonNode;
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
  var valid_601844 = query.getOrDefault("Action")
  valid_601844 = validateParameter(valid_601844, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_601844 != nil:
    section.add "Action", valid_601844
  var valid_601845 = query.getOrDefault("Version")
  valid_601845 = validateParameter(valid_601845, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601845 != nil:
    section.add "Version", valid_601845
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
  var valid_601846 = header.getOrDefault("X-Amz-Date")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Date", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Content-Sha256", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Algorithm")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Algorithm", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Signature")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Signature", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-SignedHeaders", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Credential")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Credential", valid_601852
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
  var valid_601853 = formData.getOrDefault("DomainName")
  valid_601853 = validateParameter(valid_601853, JString, required = true,
                                 default = nil)
  if valid_601853 != nil:
    section.add "DomainName", valid_601853
  var valid_601854 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_601854
  var valid_601855 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_601855
  var valid_601856 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_601856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601857: Call_PostUpdateScalingParameters_601841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601857.validator(path, query, header, formData, body)
  let scheme = call_601857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601857.url(scheme.get, call_601857.host, call_601857.base,
                         call_601857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601857, url, valid)

proc call*(call_601858: Call_PostUpdateScalingParameters_601841;
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
  var query_601859 = newJObject()
  var formData_601860 = newJObject()
  add(formData_601860, "DomainName", newJString(DomainName))
  add(formData_601860, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_601859, "Action", newJString(Action))
  add(formData_601860, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_601860, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_601859, "Version", newJString(Version))
  result = call_601858.call(nil, query_601859, nil, formData_601860, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_601841(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_601842, base: "/",
    url: url_PostUpdateScalingParameters_601843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_601822 = ref object of OpenApiRestCall_600437
proc url_GetUpdateScalingParameters_601824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateScalingParameters_601823(path: JsonNode; query: JsonNode;
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
  var valid_601825 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_601825
  var valid_601826 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_601826
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601827 = query.getOrDefault("Action")
  valid_601827 = validateParameter(valid_601827, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_601827 != nil:
    section.add "Action", valid_601827
  var valid_601828 = query.getOrDefault("DomainName")
  valid_601828 = validateParameter(valid_601828, JString, required = true,
                                 default = nil)
  if valid_601828 != nil:
    section.add "DomainName", valid_601828
  var valid_601829 = query.getOrDefault("Version")
  valid_601829 = validateParameter(valid_601829, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601829 != nil:
    section.add "Version", valid_601829
  var valid_601830 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_601830
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
  var valid_601831 = header.getOrDefault("X-Amz-Date")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Date", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Security-Token")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Security-Token", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Content-Sha256", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Algorithm")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Algorithm", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Signature")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Signature", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-SignedHeaders", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Credential")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Credential", valid_601837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601838: Call_GetUpdateScalingParameters_601822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_601838.validator(path, query, header, formData, body)
  let scheme = call_601838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601838.url(scheme.get, call_601838.host, call_601838.base,
                         call_601838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601838, url, valid)

proc call*(call_601839: Call_GetUpdateScalingParameters_601822; DomainName: string;
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
  var query_601840 = newJObject()
  add(query_601840, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_601840, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_601840, "Action", newJString(Action))
  add(query_601840, "DomainName", newJString(DomainName))
  add(query_601840, "Version", newJString(Version))
  add(query_601840, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_601839.call(nil, query_601840, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_601822(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_601823, base: "/",
    url: url_GetUpdateScalingParameters_601824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_601878 = ref object of OpenApiRestCall_600437
proc url_PostUpdateServiceAccessPolicies_601880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_601879(path: JsonNode;
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
  var valid_601881 = query.getOrDefault("Action")
  valid_601881 = validateParameter(valid_601881, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_601881 != nil:
    section.add "Action", valid_601881
  var valid_601882 = query.getOrDefault("Version")
  valid_601882 = validateParameter(valid_601882, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601882 != nil:
    section.add "Version", valid_601882
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
  var valid_601883 = header.getOrDefault("X-Amz-Date")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Date", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Security-Token")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Security-Token", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Content-Sha256", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Algorithm")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Algorithm", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Signature")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Signature", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-SignedHeaders", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Credential")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Credential", valid_601889
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
  var valid_601890 = formData.getOrDefault("DomainName")
  valid_601890 = validateParameter(valid_601890, JString, required = true,
                                 default = nil)
  if valid_601890 != nil:
    section.add "DomainName", valid_601890
  var valid_601891 = formData.getOrDefault("AccessPolicies")
  valid_601891 = validateParameter(valid_601891, JString, required = true,
                                 default = nil)
  if valid_601891 != nil:
    section.add "AccessPolicies", valid_601891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601892: Call_PostUpdateServiceAccessPolicies_601878;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_601892.validator(path, query, header, formData, body)
  let scheme = call_601892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601892.url(scheme.get, call_601892.host, call_601892.base,
                         call_601892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601892, url, valid)

proc call*(call_601893: Call_PostUpdateServiceAccessPolicies_601878;
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
  var query_601894 = newJObject()
  var formData_601895 = newJObject()
  add(formData_601895, "DomainName", newJString(DomainName))
  add(formData_601895, "AccessPolicies", newJString(AccessPolicies))
  add(query_601894, "Action", newJString(Action))
  add(query_601894, "Version", newJString(Version))
  result = call_601893.call(nil, query_601894, nil, formData_601895, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_601878(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_601879, base: "/",
    url: url_PostUpdateServiceAccessPolicies_601880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_601861 = ref object of OpenApiRestCall_600437
proc url_GetUpdateServiceAccessPolicies_601863(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_601862(path: JsonNode;
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
  var valid_601864 = query.getOrDefault("Action")
  valid_601864 = validateParameter(valid_601864, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_601864 != nil:
    section.add "Action", valid_601864
  var valid_601865 = query.getOrDefault("AccessPolicies")
  valid_601865 = validateParameter(valid_601865, JString, required = true,
                                 default = nil)
  if valid_601865 != nil:
    section.add "AccessPolicies", valid_601865
  var valid_601866 = query.getOrDefault("DomainName")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = nil)
  if valid_601866 != nil:
    section.add "DomainName", valid_601866
  var valid_601867 = query.getOrDefault("Version")
  valid_601867 = validateParameter(valid_601867, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601867 != nil:
    section.add "Version", valid_601867
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
  var valid_601868 = header.getOrDefault("X-Amz-Date")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Date", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Security-Token")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Security-Token", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Content-Sha256", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Algorithm")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Algorithm", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Signature")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Signature", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-SignedHeaders", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Credential")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Credential", valid_601874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601875: Call_GetUpdateServiceAccessPolicies_601861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_601875.validator(path, query, header, formData, body)
  let scheme = call_601875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601875.url(scheme.get, call_601875.host, call_601875.base,
                         call_601875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601875, url, valid)

proc call*(call_601876: Call_GetUpdateServiceAccessPolicies_601861;
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
  var query_601877 = newJObject()
  add(query_601877, "Action", newJString(Action))
  add(query_601877, "AccessPolicies", newJString(AccessPolicies))
  add(query_601877, "DomainName", newJString(DomainName))
  add(query_601877, "Version", newJString(Version))
  result = call_601876.call(nil, query_601877, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_601861(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_601862, base: "/",
    url: url_GetUpdateServiceAccessPolicies_601863,
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
