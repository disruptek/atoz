
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_PostBuildSuggesters_603074 = ref object of OpenApiRestCall_602466
proc url_PostBuildSuggesters_603076(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBuildSuggesters_603075(path: JsonNode; query: JsonNode;
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
  var valid_603077 = query.getOrDefault("Action")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_603077 != nil:
    section.add "Action", valid_603077
  var valid_603078 = query.getOrDefault("Version")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603078 != nil:
    section.add "Version", valid_603078
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
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Security-Token")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Security-Token", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-SignedHeaders", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Credential")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Credential", valid_603085
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603086 = formData.getOrDefault("DomainName")
  valid_603086 = validateParameter(valid_603086, JString, required = true,
                                 default = nil)
  if valid_603086 != nil:
    section.add "DomainName", valid_603086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603087: Call_PostBuildSuggesters_603074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603087.validator(path, query, header, formData, body)
  let scheme = call_603087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603087.url(scheme.get, call_603087.host, call_603087.base,
                         call_603087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603087, url, valid)

proc call*(call_603088: Call_PostBuildSuggesters_603074; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603089 = newJObject()
  var formData_603090 = newJObject()
  add(formData_603090, "DomainName", newJString(DomainName))
  add(query_603089, "Action", newJString(Action))
  add(query_603089, "Version", newJString(Version))
  result = call_603088.call(nil, query_603089, nil, formData_603090, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_603074(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_603075, base: "/",
    url: url_PostBuildSuggesters_603076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_602803 = ref object of OpenApiRestCall_602466
proc url_GetBuildSuggesters_602805(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuildSuggesters_602804(path: JsonNode; query: JsonNode;
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
  var valid_602930 = query.getOrDefault("Action")
  valid_602930 = validateParameter(valid_602930, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_602930 != nil:
    section.add "Action", valid_602930
  var valid_602931 = query.getOrDefault("DomainName")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "DomainName", valid_602931
  var valid_602932 = query.getOrDefault("Version")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602932 != nil:
    section.add "Version", valid_602932
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
  var valid_602933 = header.getOrDefault("X-Amz-Date")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Date", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Content-Sha256", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-SignedHeaders", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Credential")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Credential", valid_602939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_GetBuildSuggesters_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602962, url, valid)

proc call*(call_603033: Call_GetBuildSuggesters_602803; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_603034 = newJObject()
  add(query_603034, "Action", newJString(Action))
  add(query_603034, "DomainName", newJString(DomainName))
  add(query_603034, "Version", newJString(Version))
  result = call_603033.call(nil, query_603034, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_602803(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_602804, base: "/",
    url: url_GetBuildSuggesters_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_603107 = ref object of OpenApiRestCall_602466
proc url_PostCreateDomain_603109(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_603108(path: JsonNode; query: JsonNode;
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
  var valid_603110 = query.getOrDefault("Action")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_603110 != nil:
    section.add "Action", valid_603110
  var valid_603111 = query.getOrDefault("Version")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603111 != nil:
    section.add "Version", valid_603111
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
  var valid_603112 = header.getOrDefault("X-Amz-Date")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Date", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Security-Token")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Security-Token", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Content-Sha256", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Algorithm")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Algorithm", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-SignedHeaders", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Credential")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Credential", valid_603118
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603119 = formData.getOrDefault("DomainName")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = nil)
  if valid_603119 != nil:
    section.add "DomainName", valid_603119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_PostCreateDomain_603107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603120, url, valid)

proc call*(call_603121: Call_PostCreateDomain_603107; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603122 = newJObject()
  var formData_603123 = newJObject()
  add(formData_603123, "DomainName", newJString(DomainName))
  add(query_603122, "Action", newJString(Action))
  add(query_603122, "Version", newJString(Version))
  result = call_603121.call(nil, query_603122, nil, formData_603123, nil)

var postCreateDomain* = Call_PostCreateDomain_603107(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_603108,
    base: "/", url: url_PostCreateDomain_603109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_603091 = ref object of OpenApiRestCall_602466
proc url_GetCreateDomain_603093(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_603092(path: JsonNode; query: JsonNode;
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
  var valid_603094 = query.getOrDefault("Action")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_603094 != nil:
    section.add "Action", valid_603094
  var valid_603095 = query.getOrDefault("DomainName")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "DomainName", valid_603095
  var valid_603096 = query.getOrDefault("Version")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603096 != nil:
    section.add "Version", valid_603096
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
  var valid_603097 = header.getOrDefault("X-Amz-Date")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Date", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Security-Token")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Security-Token", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Content-Sha256", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Algorithm")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Algorithm", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Signature")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Signature", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-SignedHeaders", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Credential")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Credential", valid_603103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_GetCreateDomain_603091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_GetCreateDomain_603091; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_603106 = newJObject()
  add(query_603106, "Action", newJString(Action))
  add(query_603106, "DomainName", newJString(DomainName))
  add(query_603106, "Version", newJString(Version))
  result = call_603105.call(nil, query_603106, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_603091(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_603092,
    base: "/", url: url_GetCreateDomain_603093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_603143 = ref object of OpenApiRestCall_602466
proc url_PostDefineAnalysisScheme_603145(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineAnalysisScheme_603144(path: JsonNode; query: JsonNode;
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
  var valid_603146 = query.getOrDefault("Action")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_603146 != nil:
    section.add "Action", valid_603146
  var valid_603147 = query.getOrDefault("Version")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603147 != nil:
    section.add "Version", valid_603147
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
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
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
  var valid_603155 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_603155
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603156 = formData.getOrDefault("DomainName")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "DomainName", valid_603156
  var valid_603157 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_603157
  var valid_603158 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_603158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_PostDefineAnalysisScheme_603143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_PostDefineAnalysisScheme_603143; DomainName: string;
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
  var query_603161 = newJObject()
  var formData_603162 = newJObject()
  add(formData_603162, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_603162, "DomainName", newJString(DomainName))
  add(formData_603162, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_603161, "Action", newJString(Action))
  add(formData_603162, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_603161, "Version", newJString(Version))
  result = call_603160.call(nil, query_603161, nil, formData_603162, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_603143(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_603144, base: "/",
    url: url_PostDefineAnalysisScheme_603145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_603124 = ref object of OpenApiRestCall_602466
proc url_GetDefineAnalysisScheme_603126(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineAnalysisScheme_603125(path: JsonNode; query: JsonNode;
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
  var valid_603127 = query.getOrDefault("Action")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_603127 != nil:
    section.add "Action", valid_603127
  var valid_603128 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_603128
  var valid_603129 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_603129
  var valid_603130 = query.getOrDefault("DomainName")
  valid_603130 = validateParameter(valid_603130, JString, required = true,
                                 default = nil)
  if valid_603130 != nil:
    section.add "DomainName", valid_603130
  var valid_603131 = query.getOrDefault("Version")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603131 != nil:
    section.add "Version", valid_603131
  var valid_603132 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_603132
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
  var valid_603133 = header.getOrDefault("X-Amz-Date")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Date", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Security-Token")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Security-Token", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603140: Call_GetDefineAnalysisScheme_603124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603140.validator(path, query, header, formData, body)
  let scheme = call_603140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603140.url(scheme.get, call_603140.host, call_603140.base,
                         call_603140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603140, url, valid)

proc call*(call_603141: Call_GetDefineAnalysisScheme_603124; DomainName: string;
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
  var query_603142 = newJObject()
  add(query_603142, "Action", newJString(Action))
  add(query_603142, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_603142, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_603142, "DomainName", newJString(DomainName))
  add(query_603142, "Version", newJString(Version))
  add(query_603142, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_603141.call(nil, query_603142, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_603124(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_603125, base: "/",
    url: url_GetDefineAnalysisScheme_603126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_603181 = ref object of OpenApiRestCall_602466
proc url_PostDefineExpression_603183(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineExpression_603182(path: JsonNode; query: JsonNode;
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
  var valid_603184 = query.getOrDefault("Action")
  valid_603184 = validateParameter(valid_603184, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_603184 != nil:
    section.add "Action", valid_603184
  var valid_603185 = query.getOrDefault("Version")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603185 != nil:
    section.add "Version", valid_603185
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
  var valid_603186 = header.getOrDefault("X-Amz-Date")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Date", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Algorithm")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Algorithm", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Signature", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
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
  var valid_603193 = formData.getOrDefault("DomainName")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = nil)
  if valid_603193 != nil:
    section.add "DomainName", valid_603193
  var valid_603194 = formData.getOrDefault("Expression.ExpressionName")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "Expression.ExpressionName", valid_603194
  var valid_603195 = formData.getOrDefault("Expression.ExpressionValue")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "Expression.ExpressionValue", valid_603195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_PostDefineExpression_603181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_PostDefineExpression_603181; DomainName: string;
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
  var query_603198 = newJObject()
  var formData_603199 = newJObject()
  add(formData_603199, "DomainName", newJString(DomainName))
  add(formData_603199, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_603199, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_603198, "Action", newJString(Action))
  add(query_603198, "Version", newJString(Version))
  result = call_603197.call(nil, query_603198, nil, formData_603199, nil)

var postDefineExpression* = Call_PostDefineExpression_603181(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_603182, base: "/",
    url: url_PostDefineExpression_603183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_603163 = ref object of OpenApiRestCall_602466
proc url_GetDefineExpression_603165(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineExpression_603164(path: JsonNode; query: JsonNode;
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
  var valid_603166 = query.getOrDefault("Action")
  valid_603166 = validateParameter(valid_603166, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_603166 != nil:
    section.add "Action", valid_603166
  var valid_603167 = query.getOrDefault("Expression.ExpressionValue")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "Expression.ExpressionValue", valid_603167
  var valid_603168 = query.getOrDefault("Expression.ExpressionName")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "Expression.ExpressionName", valid_603168
  var valid_603169 = query.getOrDefault("DomainName")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "DomainName", valid_603169
  var valid_603170 = query.getOrDefault("Version")
  valid_603170 = validateParameter(valid_603170, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603170 != nil:
    section.add "Version", valid_603170
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
  var valid_603171 = header.getOrDefault("X-Amz-Date")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Date", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Content-Sha256", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Algorithm")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Algorithm", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Signature")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Signature", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Credential")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Credential", valid_603177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_GetDefineExpression_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_GetDefineExpression_603163; DomainName: string;
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
  var query_603180 = newJObject()
  add(query_603180, "Action", newJString(Action))
  add(query_603180, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_603180, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_603180, "DomainName", newJString(DomainName))
  add(query_603180, "Version", newJString(Version))
  result = call_603179.call(nil, query_603180, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_603163(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_603164, base: "/",
    url: url_GetDefineExpression_603165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_603229 = ref object of OpenApiRestCall_602466
proc url_PostDefineIndexField_603231(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_603230(path: JsonNode; query: JsonNode;
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
  var valid_603232 = query.getOrDefault("Action")
  valid_603232 = validateParameter(valid_603232, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_603232 != nil:
    section.add "Action", valid_603232
  var valid_603233 = query.getOrDefault("Version")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603233 != nil:
    section.add "Version", valid_603233
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
  var valid_603234 = header.getOrDefault("X-Amz-Date")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Date", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Security-Token")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Security-Token", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Content-Sha256", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Algorithm")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Algorithm", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-SignedHeaders", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
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
  var valid_603241 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "IndexField.TextArrayOptions", valid_603241
  var valid_603242 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "IndexField.DateArrayOptions", valid_603242
  var valid_603243 = formData.getOrDefault("IndexField.TextOptions")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "IndexField.TextOptions", valid_603243
  var valid_603244 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "IndexField.DoubleOptions", valid_603244
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603245 = formData.getOrDefault("DomainName")
  valid_603245 = validateParameter(valid_603245, JString, required = true,
                                 default = nil)
  if valid_603245 != nil:
    section.add "DomainName", valid_603245
  var valid_603246 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "IndexField.LiteralOptions", valid_603246
  var valid_603247 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_603247
  var valid_603248 = formData.getOrDefault("IndexField.DateOptions")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "IndexField.DateOptions", valid_603248
  var valid_603249 = formData.getOrDefault("IndexField.IntOptions")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "IndexField.IntOptions", valid_603249
  var valid_603250 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "IndexField.LatLonOptions", valid_603250
  var valid_603251 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "IndexField.IndexFieldType", valid_603251
  var valid_603252 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_603252
  var valid_603253 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "IndexField.IndexFieldName", valid_603253
  var valid_603254 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "IndexField.IntArrayOptions", valid_603254
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603255: Call_PostDefineIndexField_603229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603255.validator(path, query, header, formData, body)
  let scheme = call_603255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603255.url(scheme.get, call_603255.host, call_603255.base,
                         call_603255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603255, url, valid)

proc call*(call_603256: Call_PostDefineIndexField_603229; DomainName: string;
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
  var query_603257 = newJObject()
  var formData_603258 = newJObject()
  add(formData_603258, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_603258, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_603258, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_603258, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_603258, "DomainName", newJString(DomainName))
  add(formData_603258, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_603258, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_603258, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_603258, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_603258, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_603258, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_603257, "Action", newJString(Action))
  add(formData_603258, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_603258, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_603257, "Version", newJString(Version))
  add(formData_603258, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_603256.call(nil, query_603257, nil, formData_603258, nil)

var postDefineIndexField* = Call_PostDefineIndexField_603229(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_603230, base: "/",
    url: url_PostDefineIndexField_603231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_603200 = ref object of OpenApiRestCall_602466
proc url_GetDefineIndexField_603202(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_603201(path: JsonNode; query: JsonNode;
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
  var valid_603203 = query.getOrDefault("IndexField.TextOptions")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "IndexField.TextOptions", valid_603203
  var valid_603204 = query.getOrDefault("IndexField.DateOptions")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "IndexField.DateOptions", valid_603204
  var valid_603205 = query.getOrDefault("IndexField.LiteralOptions")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "IndexField.LiteralOptions", valid_603205
  var valid_603206 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_603206
  var valid_603207 = query.getOrDefault("IndexField.IndexFieldType")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "IndexField.IndexFieldType", valid_603207
  var valid_603208 = query.getOrDefault("IndexField.IntOptions")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "IndexField.IntOptions", valid_603208
  var valid_603209 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "IndexField.DateArrayOptions", valid_603209
  var valid_603210 = query.getOrDefault("IndexField.DoubleOptions")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "IndexField.DoubleOptions", valid_603210
  var valid_603211 = query.getOrDefault("IndexField.IndexFieldName")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "IndexField.IndexFieldName", valid_603211
  var valid_603212 = query.getOrDefault("IndexField.LatLonOptions")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "IndexField.LatLonOptions", valid_603212
  var valid_603213 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "IndexField.IntArrayOptions", valid_603213
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603214 = query.getOrDefault("Action")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_603214 != nil:
    section.add "Action", valid_603214
  var valid_603215 = query.getOrDefault("DomainName")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "DomainName", valid_603215
  var valid_603216 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "IndexField.TextArrayOptions", valid_603216
  var valid_603217 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_603217
  var valid_603218 = query.getOrDefault("Version")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603218 != nil:
    section.add "Version", valid_603218
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
  var valid_603219 = header.getOrDefault("X-Amz-Date")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Date", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Content-Sha256", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Algorithm")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Algorithm", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Signature")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Signature", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-SignedHeaders", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Credential")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Credential", valid_603225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_GetDefineIndexField_603200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_GetDefineIndexField_603200; DomainName: string;
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
  var query_603228 = newJObject()
  add(query_603228, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_603228, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_603228, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_603228, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_603228, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_603228, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_603228, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_603228, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_603228, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_603228, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_603228, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_603228, "Action", newJString(Action))
  add(query_603228, "DomainName", newJString(DomainName))
  add(query_603228, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_603228, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_603228, "Version", newJString(Version))
  result = call_603227.call(nil, query_603228, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_603200(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_603201, base: "/",
    url: url_GetDefineIndexField_603202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_603277 = ref object of OpenApiRestCall_602466
proc url_PostDefineSuggester_603279(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineSuggester_603278(path: JsonNode; query: JsonNode;
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
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("Version")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603281 != nil:
    section.add "Version", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Content-Sha256", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Algorithm")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Algorithm", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Signature")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Signature", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-SignedHeaders", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Credential")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Credential", valid_603288
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
  var valid_603289 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_603289
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603290 = formData.getOrDefault("DomainName")
  valid_603290 = validateParameter(valid_603290, JString, required = true,
                                 default = nil)
  if valid_603290 != nil:
    section.add "DomainName", valid_603290
  var valid_603291 = formData.getOrDefault("Suggester.SuggesterName")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "Suggester.SuggesterName", valid_603291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603292: Call_PostDefineSuggester_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603292.validator(path, query, header, formData, body)
  let scheme = call_603292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603292.url(scheme.get, call_603292.host, call_603292.base,
                         call_603292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603292, url, valid)

proc call*(call_603293: Call_PostDefineSuggester_603277; DomainName: string;
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
  var query_603294 = newJObject()
  var formData_603295 = newJObject()
  add(formData_603295, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_603295, "DomainName", newJString(DomainName))
  add(query_603294, "Action", newJString(Action))
  add(query_603294, "Version", newJString(Version))
  add(formData_603295, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_603293.call(nil, query_603294, nil, formData_603295, nil)

var postDefineSuggester* = Call_PostDefineSuggester_603277(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_603278, base: "/",
    url: url_PostDefineSuggester_603279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_603259 = ref object of OpenApiRestCall_602466
proc url_GetDefineSuggester_603261(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineSuggester_603260(path: JsonNode; query: JsonNode;
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
  var valid_603262 = query.getOrDefault("Suggester.SuggesterName")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "Suggester.SuggesterName", valid_603262
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603263 = query.getOrDefault("Action")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_603263 != nil:
    section.add "Action", valid_603263
  var valid_603264 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_603264
  var valid_603265 = query.getOrDefault("DomainName")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = nil)
  if valid_603265 != nil:
    section.add "DomainName", valid_603265
  var valid_603266 = query.getOrDefault("Version")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603266 != nil:
    section.add "Version", valid_603266
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
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Content-Sha256", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Algorithm")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Algorithm", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Signature")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Signature", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-SignedHeaders", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Credential")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Credential", valid_603273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_GetDefineSuggester_603259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603274, url, valid)

proc call*(call_603275: Call_GetDefineSuggester_603259; DomainName: string;
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
  var query_603276 = newJObject()
  add(query_603276, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_603276, "Action", newJString(Action))
  add(query_603276, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_603276, "DomainName", newJString(DomainName))
  add(query_603276, "Version", newJString(Version))
  result = call_603275.call(nil, query_603276, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_603259(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_603260, base: "/",
    url: url_GetDefineSuggester_603261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_603313 = ref object of OpenApiRestCall_602466
proc url_PostDeleteAnalysisScheme_603315(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnalysisScheme_603314(path: JsonNode; query: JsonNode;
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
  var valid_603316 = query.getOrDefault("Action")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_603316 != nil:
    section.add "Action", valid_603316
  var valid_603317 = query.getOrDefault("Version")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603317 != nil:
    section.add "Version", valid_603317
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
  var valid_603318 = header.getOrDefault("X-Amz-Date")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Date", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Security-Token")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Security-Token", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Content-Sha256", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Algorithm")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Algorithm", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Signature")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Signature", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-SignedHeaders", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Credential")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Credential", valid_603324
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603325 = formData.getOrDefault("DomainName")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "DomainName", valid_603325
  var valid_603326 = formData.getOrDefault("AnalysisSchemeName")
  valid_603326 = validateParameter(valid_603326, JString, required = true,
                                 default = nil)
  if valid_603326 != nil:
    section.add "AnalysisSchemeName", valid_603326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603327: Call_PostDeleteAnalysisScheme_603313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603327.validator(path, query, header, formData, body)
  let scheme = call_603327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603327.url(scheme.get, call_603327.host, call_603327.base,
                         call_603327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603327, url, valid)

proc call*(call_603328: Call_PostDeleteAnalysisScheme_603313; DomainName: string;
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
  var query_603329 = newJObject()
  var formData_603330 = newJObject()
  add(formData_603330, "DomainName", newJString(DomainName))
  add(formData_603330, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_603329, "Action", newJString(Action))
  add(query_603329, "Version", newJString(Version))
  result = call_603328.call(nil, query_603329, nil, formData_603330, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_603313(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_603314, base: "/",
    url: url_PostDeleteAnalysisScheme_603315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_603296 = ref object of OpenApiRestCall_602466
proc url_GetDeleteAnalysisScheme_603298(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnalysisScheme_603297(path: JsonNode; query: JsonNode;
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
  var valid_603299 = query.getOrDefault("Action")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_603299 != nil:
    section.add "Action", valid_603299
  var valid_603300 = query.getOrDefault("DomainName")
  valid_603300 = validateParameter(valid_603300, JString, required = true,
                                 default = nil)
  if valid_603300 != nil:
    section.add "DomainName", valid_603300
  var valid_603301 = query.getOrDefault("AnalysisSchemeName")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = nil)
  if valid_603301 != nil:
    section.add "AnalysisSchemeName", valid_603301
  var valid_603302 = query.getOrDefault("Version")
  valid_603302 = validateParameter(valid_603302, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603302 != nil:
    section.add "Version", valid_603302
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
  var valid_603303 = header.getOrDefault("X-Amz-Date")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Date", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Security-Token")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Security-Token", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Content-Sha256", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Algorithm")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Algorithm", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Signature")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Signature", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-SignedHeaders", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Credential")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Credential", valid_603309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603310: Call_GetDeleteAnalysisScheme_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603310.validator(path, query, header, formData, body)
  let scheme = call_603310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603310.url(scheme.get, call_603310.host, call_603310.base,
                         call_603310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603310, url, valid)

proc call*(call_603311: Call_GetDeleteAnalysisScheme_603296; DomainName: string;
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
  var query_603312 = newJObject()
  add(query_603312, "Action", newJString(Action))
  add(query_603312, "DomainName", newJString(DomainName))
  add(query_603312, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_603312, "Version", newJString(Version))
  result = call_603311.call(nil, query_603312, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_603296(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_603297, base: "/",
    url: url_GetDeleteAnalysisScheme_603298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_603347 = ref object of OpenApiRestCall_602466
proc url_PostDeleteDomain_603349(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_603348(path: JsonNode; query: JsonNode;
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
  var valid_603350 = query.getOrDefault("Action")
  valid_603350 = validateParameter(valid_603350, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603350 != nil:
    section.add "Action", valid_603350
  var valid_603351 = query.getOrDefault("Version")
  valid_603351 = validateParameter(valid_603351, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603351 != nil:
    section.add "Version", valid_603351
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
  var valid_603352 = header.getOrDefault("X-Amz-Date")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Date", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Security-Token")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Security-Token", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Content-Sha256", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Algorithm")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Algorithm", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Signature")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Signature", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-SignedHeaders", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Credential")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Credential", valid_603358
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603359 = formData.getOrDefault("DomainName")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = nil)
  if valid_603359 != nil:
    section.add "DomainName", valid_603359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603360: Call_PostDeleteDomain_603347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603360.validator(path, query, header, formData, body)
  let scheme = call_603360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603360.url(scheme.get, call_603360.host, call_603360.base,
                         call_603360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603360, url, valid)

proc call*(call_603361: Call_PostDeleteDomain_603347; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603362 = newJObject()
  var formData_603363 = newJObject()
  add(formData_603363, "DomainName", newJString(DomainName))
  add(query_603362, "Action", newJString(Action))
  add(query_603362, "Version", newJString(Version))
  result = call_603361.call(nil, query_603362, nil, formData_603363, nil)

var postDeleteDomain* = Call_PostDeleteDomain_603347(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_603348,
    base: "/", url: url_PostDeleteDomain_603349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_603331 = ref object of OpenApiRestCall_602466
proc url_GetDeleteDomain_603333(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_603332(path: JsonNode; query: JsonNode;
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
  var valid_603334 = query.getOrDefault("Action")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603334 != nil:
    section.add "Action", valid_603334
  var valid_603335 = query.getOrDefault("DomainName")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = nil)
  if valid_603335 != nil:
    section.add "DomainName", valid_603335
  var valid_603336 = query.getOrDefault("Version")
  valid_603336 = validateParameter(valid_603336, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603336 != nil:
    section.add "Version", valid_603336
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
  var valid_603337 = header.getOrDefault("X-Amz-Date")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Date", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Security-Token")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Security-Token", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Content-Sha256", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Algorithm")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Algorithm", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Signature")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Signature", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-SignedHeaders", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Credential")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Credential", valid_603343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603344: Call_GetDeleteDomain_603331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603344.validator(path, query, header, formData, body)
  let scheme = call_603344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603344.url(scheme.get, call_603344.host, call_603344.base,
                         call_603344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603344, url, valid)

proc call*(call_603345: Call_GetDeleteDomain_603331; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_603346 = newJObject()
  add(query_603346, "Action", newJString(Action))
  add(query_603346, "DomainName", newJString(DomainName))
  add(query_603346, "Version", newJString(Version))
  result = call_603345.call(nil, query_603346, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_603331(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_603332,
    base: "/", url: url_GetDeleteDomain_603333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_603381 = ref object of OpenApiRestCall_602466
proc url_PostDeleteExpression_603383(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteExpression_603382(path: JsonNode; query: JsonNode;
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
  var valid_603384 = query.getOrDefault("Action")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_603384 != nil:
    section.add "Action", valid_603384
  var valid_603385 = query.getOrDefault("Version")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603385 != nil:
    section.add "Version", valid_603385
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
  var valid_603386 = header.getOrDefault("X-Amz-Date")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Date", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Security-Token")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Security-Token", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Content-Sha256", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Algorithm")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Algorithm", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Signature")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Signature", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-SignedHeaders", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Credential")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Credential", valid_603392
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_603393 = formData.getOrDefault("ExpressionName")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = nil)
  if valid_603393 != nil:
    section.add "ExpressionName", valid_603393
  var valid_603394 = formData.getOrDefault("DomainName")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "DomainName", valid_603394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_PostDeleteExpression_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603395, url, valid)

proc call*(call_603396: Call_PostDeleteExpression_603381; ExpressionName: string;
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
  var query_603397 = newJObject()
  var formData_603398 = newJObject()
  add(formData_603398, "ExpressionName", newJString(ExpressionName))
  add(formData_603398, "DomainName", newJString(DomainName))
  add(query_603397, "Action", newJString(Action))
  add(query_603397, "Version", newJString(Version))
  result = call_603396.call(nil, query_603397, nil, formData_603398, nil)

var postDeleteExpression* = Call_PostDeleteExpression_603381(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_603382, base: "/",
    url: url_PostDeleteExpression_603383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_603364 = ref object of OpenApiRestCall_602466
proc url_GetDeleteExpression_603366(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteExpression_603365(path: JsonNode; query: JsonNode;
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
  var valid_603367 = query.getOrDefault("Action")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_603367 != nil:
    section.add "Action", valid_603367
  var valid_603368 = query.getOrDefault("ExpressionName")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = nil)
  if valid_603368 != nil:
    section.add "ExpressionName", valid_603368
  var valid_603369 = query.getOrDefault("DomainName")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = nil)
  if valid_603369 != nil:
    section.add "DomainName", valid_603369
  var valid_603370 = query.getOrDefault("Version")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603370 != nil:
    section.add "Version", valid_603370
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
  var valid_603371 = header.getOrDefault("X-Amz-Date")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Date", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Security-Token")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Security-Token", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Content-Sha256", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Algorithm")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Algorithm", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Signature")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Signature", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-SignedHeaders", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Credential")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Credential", valid_603377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_GetDeleteExpression_603364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_GetDeleteExpression_603364; ExpressionName: string;
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
  var query_603380 = newJObject()
  add(query_603380, "Action", newJString(Action))
  add(query_603380, "ExpressionName", newJString(ExpressionName))
  add(query_603380, "DomainName", newJString(DomainName))
  add(query_603380, "Version", newJString(Version))
  result = call_603379.call(nil, query_603380, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_603364(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_603365, base: "/",
    url: url_GetDeleteExpression_603366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_603416 = ref object of OpenApiRestCall_602466
proc url_PostDeleteIndexField_603418(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_603417(path: JsonNode; query: JsonNode;
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
  var valid_603419 = query.getOrDefault("Action")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_603419 != nil:
    section.add "Action", valid_603419
  var valid_603420 = query.getOrDefault("Version")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603420 != nil:
    section.add "Version", valid_603420
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
  var valid_603421 = header.getOrDefault("X-Amz-Date")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Date", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603428 = formData.getOrDefault("DomainName")
  valid_603428 = validateParameter(valid_603428, JString, required = true,
                                 default = nil)
  if valid_603428 != nil:
    section.add "DomainName", valid_603428
  var valid_603429 = formData.getOrDefault("IndexFieldName")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "IndexFieldName", valid_603429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_PostDeleteIndexField_603416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_PostDeleteIndexField_603416; DomainName: string;
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
  var query_603432 = newJObject()
  var formData_603433 = newJObject()
  add(formData_603433, "DomainName", newJString(DomainName))
  add(formData_603433, "IndexFieldName", newJString(IndexFieldName))
  add(query_603432, "Action", newJString(Action))
  add(query_603432, "Version", newJString(Version))
  result = call_603431.call(nil, query_603432, nil, formData_603433, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_603416(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_603417, base: "/",
    url: url_PostDeleteIndexField_603418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_603399 = ref object of OpenApiRestCall_602466
proc url_GetDeleteIndexField_603401(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_603400(path: JsonNode; query: JsonNode;
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
  var valid_603402 = query.getOrDefault("IndexFieldName")
  valid_603402 = validateParameter(valid_603402, JString, required = true,
                                 default = nil)
  if valid_603402 != nil:
    section.add "IndexFieldName", valid_603402
  var valid_603403 = query.getOrDefault("Action")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_603403 != nil:
    section.add "Action", valid_603403
  var valid_603404 = query.getOrDefault("DomainName")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "DomainName", valid_603404
  var valid_603405 = query.getOrDefault("Version")
  valid_603405 = validateParameter(valid_603405, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603405 != nil:
    section.add "Version", valid_603405
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603413: Call_GetDeleteIndexField_603399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603413.validator(path, query, header, formData, body)
  let scheme = call_603413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603413.url(scheme.get, call_603413.host, call_603413.base,
                         call_603413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603413, url, valid)

proc call*(call_603414: Call_GetDeleteIndexField_603399; IndexFieldName: string;
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
  var query_603415 = newJObject()
  add(query_603415, "IndexFieldName", newJString(IndexFieldName))
  add(query_603415, "Action", newJString(Action))
  add(query_603415, "DomainName", newJString(DomainName))
  add(query_603415, "Version", newJString(Version))
  result = call_603414.call(nil, query_603415, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_603399(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_603400, base: "/",
    url: url_GetDeleteIndexField_603401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_603451 = ref object of OpenApiRestCall_602466
proc url_PostDeleteSuggester_603453(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteSuggester_603452(path: JsonNode; query: JsonNode;
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
  var valid_603454 = query.getOrDefault("Action")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_603454 != nil:
    section.add "Action", valid_603454
  var valid_603455 = query.getOrDefault("Version")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603455 != nil:
    section.add "Version", valid_603455
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
  var valid_603456 = header.getOrDefault("X-Amz-Date")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Date", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Security-Token")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Security-Token", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Content-Sha256", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Algorithm")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Algorithm", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Signature")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Signature", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-SignedHeaders", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Credential")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Credential", valid_603462
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603463 = formData.getOrDefault("DomainName")
  valid_603463 = validateParameter(valid_603463, JString, required = true,
                                 default = nil)
  if valid_603463 != nil:
    section.add "DomainName", valid_603463
  var valid_603464 = formData.getOrDefault("SuggesterName")
  valid_603464 = validateParameter(valid_603464, JString, required = true,
                                 default = nil)
  if valid_603464 != nil:
    section.add "SuggesterName", valid_603464
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603465: Call_PostDeleteSuggester_603451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603465.validator(path, query, header, formData, body)
  let scheme = call_603465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603465.url(scheme.get, call_603465.host, call_603465.base,
                         call_603465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603465, url, valid)

proc call*(call_603466: Call_PostDeleteSuggester_603451; DomainName: string;
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
  var query_603467 = newJObject()
  var formData_603468 = newJObject()
  add(formData_603468, "DomainName", newJString(DomainName))
  add(query_603467, "Action", newJString(Action))
  add(formData_603468, "SuggesterName", newJString(SuggesterName))
  add(query_603467, "Version", newJString(Version))
  result = call_603466.call(nil, query_603467, nil, formData_603468, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_603451(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_603452, base: "/",
    url: url_PostDeleteSuggester_603453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_603434 = ref object of OpenApiRestCall_602466
proc url_GetDeleteSuggester_603436(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteSuggester_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = query.getOrDefault("Action")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_603437 != nil:
    section.add "Action", valid_603437
  var valid_603438 = query.getOrDefault("SuggesterName")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = nil)
  if valid_603438 != nil:
    section.add "SuggesterName", valid_603438
  var valid_603439 = query.getOrDefault("DomainName")
  valid_603439 = validateParameter(valid_603439, JString, required = true,
                                 default = nil)
  if valid_603439 != nil:
    section.add "DomainName", valid_603439
  var valid_603440 = query.getOrDefault("Version")
  valid_603440 = validateParameter(valid_603440, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603440 != nil:
    section.add "Version", valid_603440
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
  var valid_603441 = header.getOrDefault("X-Amz-Date")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Date", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Security-Token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Security-Token", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Content-Sha256", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Algorithm")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Algorithm", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Signature")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Signature", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-SignedHeaders", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Credential")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Credential", valid_603447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_GetDeleteSuggester_603434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603448, url, valid)

proc call*(call_603449: Call_GetDeleteSuggester_603434; SuggesterName: string;
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
  var query_603450 = newJObject()
  add(query_603450, "Action", newJString(Action))
  add(query_603450, "SuggesterName", newJString(SuggesterName))
  add(query_603450, "DomainName", newJString(DomainName))
  add(query_603450, "Version", newJString(Version))
  result = call_603449.call(nil, query_603450, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_603434(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_603435, base: "/",
    url: url_GetDeleteSuggester_603436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_603487 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAnalysisSchemes_603489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnalysisSchemes_603488(path: JsonNode; query: JsonNode;
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
  var valid_603490 = query.getOrDefault("Action")
  valid_603490 = validateParameter(valid_603490, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_603490 != nil:
    section.add "Action", valid_603490
  var valid_603491 = query.getOrDefault("Version")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603491 != nil:
    section.add "Version", valid_603491
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
  var valid_603492 = header.getOrDefault("X-Amz-Date")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Date", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Security-Token")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Security-Token", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Content-Sha256", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Algorithm")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Algorithm", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Signature")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Signature", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-SignedHeaders", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Credential")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Credential", valid_603498
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
  var valid_603499 = formData.getOrDefault("DomainName")
  valid_603499 = validateParameter(valid_603499, JString, required = true,
                                 default = nil)
  if valid_603499 != nil:
    section.add "DomainName", valid_603499
  var valid_603500 = formData.getOrDefault("Deployed")
  valid_603500 = validateParameter(valid_603500, JBool, required = false, default = nil)
  if valid_603500 != nil:
    section.add "Deployed", valid_603500
  var valid_603501 = formData.getOrDefault("AnalysisSchemeNames")
  valid_603501 = validateParameter(valid_603501, JArray, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "AnalysisSchemeNames", valid_603501
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_PostDescribeAnalysisSchemes_603487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603502, url, valid)

proc call*(call_603503: Call_PostDescribeAnalysisSchemes_603487;
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
  var query_603504 = newJObject()
  var formData_603505 = newJObject()
  add(formData_603505, "DomainName", newJString(DomainName))
  add(formData_603505, "Deployed", newJBool(Deployed))
  add(query_603504, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_603505.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_603504, "Version", newJString(Version))
  result = call_603503.call(nil, query_603504, nil, formData_603505, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_603487(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_603488, base: "/",
    url: url_PostDescribeAnalysisSchemes_603489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_603469 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAnalysisSchemes_603471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnalysisSchemes_603470(path: JsonNode; query: JsonNode;
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
  var valid_603472 = query.getOrDefault("Deployed")
  valid_603472 = validateParameter(valid_603472, JBool, required = false, default = nil)
  if valid_603472 != nil:
    section.add "Deployed", valid_603472
  var valid_603473 = query.getOrDefault("AnalysisSchemeNames")
  valid_603473 = validateParameter(valid_603473, JArray, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "AnalysisSchemeNames", valid_603473
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603474 = query.getOrDefault("Action")
  valid_603474 = validateParameter(valid_603474, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_603474 != nil:
    section.add "Action", valid_603474
  var valid_603475 = query.getOrDefault("DomainName")
  valid_603475 = validateParameter(valid_603475, JString, required = true,
                                 default = nil)
  if valid_603475 != nil:
    section.add "DomainName", valid_603475
  var valid_603476 = query.getOrDefault("Version")
  valid_603476 = validateParameter(valid_603476, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603476 != nil:
    section.add "Version", valid_603476
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
  var valid_603477 = header.getOrDefault("X-Amz-Date")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Date", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Security-Token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Security-Token", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Content-Sha256", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Algorithm")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Algorithm", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Signature")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Signature", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-SignedHeaders", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Credential")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Credential", valid_603483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603484: Call_GetDescribeAnalysisSchemes_603469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603484.validator(path, query, header, formData, body)
  let scheme = call_603484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603484.url(scheme.get, call_603484.host, call_603484.base,
                         call_603484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603484, url, valid)

proc call*(call_603485: Call_GetDescribeAnalysisSchemes_603469; DomainName: string;
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
  var query_603486 = newJObject()
  add(query_603486, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_603486.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_603486, "Action", newJString(Action))
  add(query_603486, "DomainName", newJString(DomainName))
  add(query_603486, "Version", newJString(Version))
  result = call_603485.call(nil, query_603486, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_603469(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_603470, base: "/",
    url: url_GetDescribeAnalysisSchemes_603471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_603523 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAvailabilityOptions_603525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_603524(path: JsonNode;
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
  var valid_603526 = query.getOrDefault("Action")
  valid_603526 = validateParameter(valid_603526, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_603526 != nil:
    section.add "Action", valid_603526
  var valid_603527 = query.getOrDefault("Version")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603527 != nil:
    section.add "Version", valid_603527
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
  var valid_603528 = header.getOrDefault("X-Amz-Date")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Date", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Security-Token")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Security-Token", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Content-Sha256", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Algorithm")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Algorithm", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Signature")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Signature", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-SignedHeaders", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Credential")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Credential", valid_603534
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603535 = formData.getOrDefault("DomainName")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = nil)
  if valid_603535 != nil:
    section.add "DomainName", valid_603535
  var valid_603536 = formData.getOrDefault("Deployed")
  valid_603536 = validateParameter(valid_603536, JBool, required = false, default = nil)
  if valid_603536 != nil:
    section.add "Deployed", valid_603536
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603537: Call_PostDescribeAvailabilityOptions_603523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603537.validator(path, query, header, formData, body)
  let scheme = call_603537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603537.url(scheme.get, call_603537.host, call_603537.base,
                         call_603537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603537, url, valid)

proc call*(call_603538: Call_PostDescribeAvailabilityOptions_603523;
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
  var query_603539 = newJObject()
  var formData_603540 = newJObject()
  add(formData_603540, "DomainName", newJString(DomainName))
  add(formData_603540, "Deployed", newJBool(Deployed))
  add(query_603539, "Action", newJString(Action))
  add(query_603539, "Version", newJString(Version))
  result = call_603538.call(nil, query_603539, nil, formData_603540, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_603523(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_603524, base: "/",
    url: url_PostDescribeAvailabilityOptions_603525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_603506 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAvailabilityOptions_603508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_603507(path: JsonNode;
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
  var valid_603509 = query.getOrDefault("Deployed")
  valid_603509 = validateParameter(valid_603509, JBool, required = false, default = nil)
  if valid_603509 != nil:
    section.add "Deployed", valid_603509
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603510 = query.getOrDefault("Action")
  valid_603510 = validateParameter(valid_603510, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_603510 != nil:
    section.add "Action", valid_603510
  var valid_603511 = query.getOrDefault("DomainName")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = nil)
  if valid_603511 != nil:
    section.add "DomainName", valid_603511
  var valid_603512 = query.getOrDefault("Version")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603512 != nil:
    section.add "Version", valid_603512
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
  var valid_603513 = header.getOrDefault("X-Amz-Date")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Date", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Security-Token")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Security-Token", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Content-Sha256", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Algorithm")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Algorithm", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Signature")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Signature", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Credential")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Credential", valid_603519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603520: Call_GetDescribeAvailabilityOptions_603506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603520.validator(path, query, header, formData, body)
  let scheme = call_603520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603520.url(scheme.get, call_603520.host, call_603520.base,
                         call_603520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603520, url, valid)

proc call*(call_603521: Call_GetDescribeAvailabilityOptions_603506;
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
  var query_603522 = newJObject()
  add(query_603522, "Deployed", newJBool(Deployed))
  add(query_603522, "Action", newJString(Action))
  add(query_603522, "DomainName", newJString(DomainName))
  add(query_603522, "Version", newJString(Version))
  result = call_603521.call(nil, query_603522, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_603506(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_603507, base: "/",
    url: url_GetDescribeAvailabilityOptions_603508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_603557 = ref object of OpenApiRestCall_602466
proc url_PostDescribeDomains_603559(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_603558(path: JsonNode; query: JsonNode;
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
  var valid_603560 = query.getOrDefault("Action")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_603560 != nil:
    section.add "Action", valid_603560
  var valid_603561 = query.getOrDefault("Version")
  valid_603561 = validateParameter(valid_603561, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603561 != nil:
    section.add "Version", valid_603561
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
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Content-Sha256", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Algorithm")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Algorithm", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Signature")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Signature", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-SignedHeaders", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Credential")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Credential", valid_603568
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_603569 = formData.getOrDefault("DomainNames")
  valid_603569 = validateParameter(valid_603569, JArray, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "DomainNames", valid_603569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603570: Call_PostDescribeDomains_603557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603570.validator(path, query, header, formData, body)
  let scheme = call_603570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603570.url(scheme.get, call_603570.host, call_603570.base,
                         call_603570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603570, url, valid)

proc call*(call_603571: Call_PostDescribeDomains_603557;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603572 = newJObject()
  var formData_603573 = newJObject()
  if DomainNames != nil:
    formData_603573.add "DomainNames", DomainNames
  add(query_603572, "Action", newJString(Action))
  add(query_603572, "Version", newJString(Version))
  result = call_603571.call(nil, query_603572, nil, formData_603573, nil)

var postDescribeDomains* = Call_PostDescribeDomains_603557(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_603558, base: "/",
    url: url_PostDescribeDomains_603559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_603541 = ref object of OpenApiRestCall_602466
proc url_GetDescribeDomains_603543(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_603542(path: JsonNode; query: JsonNode;
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
  var valid_603544 = query.getOrDefault("DomainNames")
  valid_603544 = validateParameter(valid_603544, JArray, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "DomainNames", valid_603544
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603545 = query.getOrDefault("Action")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_603545 != nil:
    section.add "Action", valid_603545
  var valid_603546 = query.getOrDefault("Version")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603546 != nil:
    section.add "Version", valid_603546
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
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Content-Sha256", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Credential")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Credential", valid_603553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603554: Call_GetDescribeDomains_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603554.validator(path, query, header, formData, body)
  let scheme = call_603554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603554.url(scheme.get, call_603554.host, call_603554.base,
                         call_603554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603554, url, valid)

proc call*(call_603555: Call_GetDescribeDomains_603541;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603556 = newJObject()
  if DomainNames != nil:
    query_603556.add "DomainNames", DomainNames
  add(query_603556, "Action", newJString(Action))
  add(query_603556, "Version", newJString(Version))
  result = call_603555.call(nil, query_603556, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_603541(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_603542, base: "/",
    url: url_GetDescribeDomains_603543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_603592 = ref object of OpenApiRestCall_602466
proc url_PostDescribeExpressions_603594(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeExpressions_603593(path: JsonNode; query: JsonNode;
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
  var valid_603595 = query.getOrDefault("Action")
  valid_603595 = validateParameter(valid_603595, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_603595 != nil:
    section.add "Action", valid_603595
  var valid_603596 = query.getOrDefault("Version")
  valid_603596 = validateParameter(valid_603596, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603596 != nil:
    section.add "Version", valid_603596
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
  var valid_603597 = header.getOrDefault("X-Amz-Date")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Date", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Security-Token")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Security-Token", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Content-Sha256", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Algorithm")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Algorithm", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Signature")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Signature", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-SignedHeaders", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
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
  var valid_603604 = formData.getOrDefault("DomainName")
  valid_603604 = validateParameter(valid_603604, JString, required = true,
                                 default = nil)
  if valid_603604 != nil:
    section.add "DomainName", valid_603604
  var valid_603605 = formData.getOrDefault("Deployed")
  valid_603605 = validateParameter(valid_603605, JBool, required = false, default = nil)
  if valid_603605 != nil:
    section.add "Deployed", valid_603605
  var valid_603606 = formData.getOrDefault("ExpressionNames")
  valid_603606 = validateParameter(valid_603606, JArray, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "ExpressionNames", valid_603606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_PostDescribeExpressions_603592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_PostDescribeExpressions_603592; DomainName: string;
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
  var query_603609 = newJObject()
  var formData_603610 = newJObject()
  add(formData_603610, "DomainName", newJString(DomainName))
  add(formData_603610, "Deployed", newJBool(Deployed))
  add(query_603609, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_603610.add "ExpressionNames", ExpressionNames
  add(query_603609, "Version", newJString(Version))
  result = call_603608.call(nil, query_603609, nil, formData_603610, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_603592(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_603593, base: "/",
    url: url_PostDescribeExpressions_603594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_603574 = ref object of OpenApiRestCall_602466
proc url_GetDescribeExpressions_603576(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeExpressions_603575(path: JsonNode; query: JsonNode;
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
  var valid_603577 = query.getOrDefault("Deployed")
  valid_603577 = validateParameter(valid_603577, JBool, required = false, default = nil)
  if valid_603577 != nil:
    section.add "Deployed", valid_603577
  var valid_603578 = query.getOrDefault("ExpressionNames")
  valid_603578 = validateParameter(valid_603578, JArray, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "ExpressionNames", valid_603578
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603579 = query.getOrDefault("Action")
  valid_603579 = validateParameter(valid_603579, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_603579 != nil:
    section.add "Action", valid_603579
  var valid_603580 = query.getOrDefault("DomainName")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = nil)
  if valid_603580 != nil:
    section.add "DomainName", valid_603580
  var valid_603581 = query.getOrDefault("Version")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603581 != nil:
    section.add "Version", valid_603581
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
  var valid_603582 = header.getOrDefault("X-Amz-Date")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Date", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Security-Token")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Security-Token", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603589: Call_GetDescribeExpressions_603574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603589.validator(path, query, header, formData, body)
  let scheme = call_603589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603589.url(scheme.get, call_603589.host, call_603589.base,
                         call_603589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603589, url, valid)

proc call*(call_603590: Call_GetDescribeExpressions_603574; DomainName: string;
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
  var query_603591 = newJObject()
  add(query_603591, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_603591.add "ExpressionNames", ExpressionNames
  add(query_603591, "Action", newJString(Action))
  add(query_603591, "DomainName", newJString(DomainName))
  add(query_603591, "Version", newJString(Version))
  result = call_603590.call(nil, query_603591, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_603574(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_603575, base: "/",
    url: url_GetDescribeExpressions_603576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_603629 = ref object of OpenApiRestCall_602466
proc url_PostDescribeIndexFields_603631(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_603630(path: JsonNode; query: JsonNode;
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
  var valid_603632 = query.getOrDefault("Action")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_603632 != nil:
    section.add "Action", valid_603632
  var valid_603633 = query.getOrDefault("Version")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603633 != nil:
    section.add "Version", valid_603633
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
  var valid_603634 = header.getOrDefault("X-Amz-Date")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Date", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Security-Token")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Security-Token", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Content-Sha256", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Algorithm")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Algorithm", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Signature")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Signature", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-SignedHeaders", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Credential")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Credential", valid_603640
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
  var valid_603641 = formData.getOrDefault("DomainName")
  valid_603641 = validateParameter(valid_603641, JString, required = true,
                                 default = nil)
  if valid_603641 != nil:
    section.add "DomainName", valid_603641
  var valid_603642 = formData.getOrDefault("Deployed")
  valid_603642 = validateParameter(valid_603642, JBool, required = false, default = nil)
  if valid_603642 != nil:
    section.add "Deployed", valid_603642
  var valid_603643 = formData.getOrDefault("FieldNames")
  valid_603643 = validateParameter(valid_603643, JArray, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "FieldNames", valid_603643
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603644: Call_PostDescribeIndexFields_603629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603644.validator(path, query, header, formData, body)
  let scheme = call_603644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603644.url(scheme.get, call_603644.host, call_603644.base,
                         call_603644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603644, url, valid)

proc call*(call_603645: Call_PostDescribeIndexFields_603629; DomainName: string;
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
  var query_603646 = newJObject()
  var formData_603647 = newJObject()
  add(formData_603647, "DomainName", newJString(DomainName))
  add(formData_603647, "Deployed", newJBool(Deployed))
  add(query_603646, "Action", newJString(Action))
  if FieldNames != nil:
    formData_603647.add "FieldNames", FieldNames
  add(query_603646, "Version", newJString(Version))
  result = call_603645.call(nil, query_603646, nil, formData_603647, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_603629(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_603630, base: "/",
    url: url_PostDescribeIndexFields_603631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_603611 = ref object of OpenApiRestCall_602466
proc url_GetDescribeIndexFields_603613(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_603612(path: JsonNode; query: JsonNode;
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
  var valid_603614 = query.getOrDefault("Deployed")
  valid_603614 = validateParameter(valid_603614, JBool, required = false, default = nil)
  if valid_603614 != nil:
    section.add "Deployed", valid_603614
  var valid_603615 = query.getOrDefault("FieldNames")
  valid_603615 = validateParameter(valid_603615, JArray, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "FieldNames", valid_603615
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603616 = query.getOrDefault("Action")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_603616 != nil:
    section.add "Action", valid_603616
  var valid_603617 = query.getOrDefault("DomainName")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "DomainName", valid_603617
  var valid_603618 = query.getOrDefault("Version")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603618 != nil:
    section.add "Version", valid_603618
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
  var valid_603619 = header.getOrDefault("X-Amz-Date")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Date", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Security-Token")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Security-Token", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Content-Sha256", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Algorithm")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Algorithm", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Signature")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Signature", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-SignedHeaders", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Credential")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Credential", valid_603625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603626: Call_GetDescribeIndexFields_603611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603626.validator(path, query, header, formData, body)
  let scheme = call_603626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603626.url(scheme.get, call_603626.host, call_603626.base,
                         call_603626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603626, url, valid)

proc call*(call_603627: Call_GetDescribeIndexFields_603611; DomainName: string;
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
  var query_603628 = newJObject()
  add(query_603628, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_603628.add "FieldNames", FieldNames
  add(query_603628, "Action", newJString(Action))
  add(query_603628, "DomainName", newJString(DomainName))
  add(query_603628, "Version", newJString(Version))
  result = call_603627.call(nil, query_603628, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_603611(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_603612, base: "/",
    url: url_GetDescribeIndexFields_603613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_603664 = ref object of OpenApiRestCall_602466
proc url_PostDescribeScalingParameters_603666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeScalingParameters_603665(path: JsonNode; query: JsonNode;
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
  var valid_603667 = query.getOrDefault("Action")
  valid_603667 = validateParameter(valid_603667, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_603667 != nil:
    section.add "Action", valid_603667
  var valid_603668 = query.getOrDefault("Version")
  valid_603668 = validateParameter(valid_603668, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603668 != nil:
    section.add "Version", valid_603668
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
  var valid_603669 = header.getOrDefault("X-Amz-Date")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Date", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Security-Token")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Security-Token", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Content-Sha256", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Algorithm")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Algorithm", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Signature")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Signature", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-SignedHeaders", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Credential")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Credential", valid_603675
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603676 = formData.getOrDefault("DomainName")
  valid_603676 = validateParameter(valid_603676, JString, required = true,
                                 default = nil)
  if valid_603676 != nil:
    section.add "DomainName", valid_603676
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603677: Call_PostDescribeScalingParameters_603664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603677.validator(path, query, header, formData, body)
  let scheme = call_603677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603677.url(scheme.get, call_603677.host, call_603677.base,
                         call_603677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603677, url, valid)

proc call*(call_603678: Call_PostDescribeScalingParameters_603664;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603679 = newJObject()
  var formData_603680 = newJObject()
  add(formData_603680, "DomainName", newJString(DomainName))
  add(query_603679, "Action", newJString(Action))
  add(query_603679, "Version", newJString(Version))
  result = call_603678.call(nil, query_603679, nil, formData_603680, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_603664(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_603665, base: "/",
    url: url_PostDescribeScalingParameters_603666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_603648 = ref object of OpenApiRestCall_602466
proc url_GetDescribeScalingParameters_603650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeScalingParameters_603649(path: JsonNode; query: JsonNode;
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
  var valid_603651 = query.getOrDefault("Action")
  valid_603651 = validateParameter(valid_603651, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_603651 != nil:
    section.add "Action", valid_603651
  var valid_603652 = query.getOrDefault("DomainName")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = nil)
  if valid_603652 != nil:
    section.add "DomainName", valid_603652
  var valid_603653 = query.getOrDefault("Version")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603653 != nil:
    section.add "Version", valid_603653
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
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Security-Token")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Security-Token", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Content-Sha256", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Algorithm")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Algorithm", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Signature")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Signature", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-SignedHeaders", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Credential")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Credential", valid_603660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_GetDescribeScalingParameters_603648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_GetDescribeScalingParameters_603648;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_603663 = newJObject()
  add(query_603663, "Action", newJString(Action))
  add(query_603663, "DomainName", newJString(DomainName))
  add(query_603663, "Version", newJString(Version))
  result = call_603662.call(nil, query_603663, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_603648(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_603649, base: "/",
    url: url_GetDescribeScalingParameters_603650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_603698 = ref object of OpenApiRestCall_602466
proc url_PostDescribeServiceAccessPolicies_603700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_603699(path: JsonNode;
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
  var valid_603701 = query.getOrDefault("Action")
  valid_603701 = validateParameter(valid_603701, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_603701 != nil:
    section.add "Action", valid_603701
  var valid_603702 = query.getOrDefault("Version")
  valid_603702 = validateParameter(valid_603702, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603702 != nil:
    section.add "Version", valid_603702
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
  var valid_603703 = header.getOrDefault("X-Amz-Date")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Date", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Security-Token")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Security-Token", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Content-Sha256", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Algorithm")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Algorithm", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Signature")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Signature", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-SignedHeaders", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Credential")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Credential", valid_603709
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603710 = formData.getOrDefault("DomainName")
  valid_603710 = validateParameter(valid_603710, JString, required = true,
                                 default = nil)
  if valid_603710 != nil:
    section.add "DomainName", valid_603710
  var valid_603711 = formData.getOrDefault("Deployed")
  valid_603711 = validateParameter(valid_603711, JBool, required = false, default = nil)
  if valid_603711 != nil:
    section.add "Deployed", valid_603711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603712: Call_PostDescribeServiceAccessPolicies_603698;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603712.validator(path, query, header, formData, body)
  let scheme = call_603712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603712.url(scheme.get, call_603712.host, call_603712.base,
                         call_603712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603712, url, valid)

proc call*(call_603713: Call_PostDescribeServiceAccessPolicies_603698;
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
  var query_603714 = newJObject()
  var formData_603715 = newJObject()
  add(formData_603715, "DomainName", newJString(DomainName))
  add(formData_603715, "Deployed", newJBool(Deployed))
  add(query_603714, "Action", newJString(Action))
  add(query_603714, "Version", newJString(Version))
  result = call_603713.call(nil, query_603714, nil, formData_603715, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_603698(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_603699, base: "/",
    url: url_PostDescribeServiceAccessPolicies_603700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_603681 = ref object of OpenApiRestCall_602466
proc url_GetDescribeServiceAccessPolicies_603683(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_603682(path: JsonNode;
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
  var valid_603684 = query.getOrDefault("Deployed")
  valid_603684 = validateParameter(valid_603684, JBool, required = false, default = nil)
  if valid_603684 != nil:
    section.add "Deployed", valid_603684
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603685 = query.getOrDefault("Action")
  valid_603685 = validateParameter(valid_603685, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_603685 != nil:
    section.add "Action", valid_603685
  var valid_603686 = query.getOrDefault("DomainName")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "DomainName", valid_603686
  var valid_603687 = query.getOrDefault("Version")
  valid_603687 = validateParameter(valid_603687, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603687 != nil:
    section.add "Version", valid_603687
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
  var valid_603688 = header.getOrDefault("X-Amz-Date")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Date", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Security-Token")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Security-Token", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Content-Sha256", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Algorithm")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Algorithm", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Signature")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Signature", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-SignedHeaders", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Credential")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Credential", valid_603694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603695: Call_GetDescribeServiceAccessPolicies_603681;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603695.validator(path, query, header, formData, body)
  let scheme = call_603695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603695.url(scheme.get, call_603695.host, call_603695.base,
                         call_603695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603695, url, valid)

proc call*(call_603696: Call_GetDescribeServiceAccessPolicies_603681;
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
  var query_603697 = newJObject()
  add(query_603697, "Deployed", newJBool(Deployed))
  add(query_603697, "Action", newJString(Action))
  add(query_603697, "DomainName", newJString(DomainName))
  add(query_603697, "Version", newJString(Version))
  result = call_603696.call(nil, query_603697, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_603681(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_603682, base: "/",
    url: url_GetDescribeServiceAccessPolicies_603683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_603734 = ref object of OpenApiRestCall_602466
proc url_PostDescribeSuggesters_603736(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSuggesters_603735(path: JsonNode; query: JsonNode;
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
  var valid_603737 = query.getOrDefault("Action")
  valid_603737 = validateParameter(valid_603737, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_603737 != nil:
    section.add "Action", valid_603737
  var valid_603738 = query.getOrDefault("Version")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603738 != nil:
    section.add "Version", valid_603738
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
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Content-Sha256", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Algorithm")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Algorithm", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Signature")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Signature", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-SignedHeaders", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Credential")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Credential", valid_603745
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
  var valid_603746 = formData.getOrDefault("DomainName")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "DomainName", valid_603746
  var valid_603747 = formData.getOrDefault("Deployed")
  valid_603747 = validateParameter(valid_603747, JBool, required = false, default = nil)
  if valid_603747 != nil:
    section.add "Deployed", valid_603747
  var valid_603748 = formData.getOrDefault("SuggesterNames")
  valid_603748 = validateParameter(valid_603748, JArray, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "SuggesterNames", valid_603748
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603749: Call_PostDescribeSuggesters_603734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603749.validator(path, query, header, formData, body)
  let scheme = call_603749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603749.url(scheme.get, call_603749.host, call_603749.base,
                         call_603749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603749, url, valid)

proc call*(call_603750: Call_PostDescribeSuggesters_603734; DomainName: string;
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
  var query_603751 = newJObject()
  var formData_603752 = newJObject()
  add(formData_603752, "DomainName", newJString(DomainName))
  add(formData_603752, "Deployed", newJBool(Deployed))
  add(query_603751, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_603752.add "SuggesterNames", SuggesterNames
  add(query_603751, "Version", newJString(Version))
  result = call_603750.call(nil, query_603751, nil, formData_603752, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_603734(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_603735, base: "/",
    url: url_PostDescribeSuggesters_603736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_603716 = ref object of OpenApiRestCall_602466
proc url_GetDescribeSuggesters_603718(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSuggesters_603717(path: JsonNode; query: JsonNode;
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
  var valid_603719 = query.getOrDefault("Deployed")
  valid_603719 = validateParameter(valid_603719, JBool, required = false, default = nil)
  if valid_603719 != nil:
    section.add "Deployed", valid_603719
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603720 = query.getOrDefault("Action")
  valid_603720 = validateParameter(valid_603720, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_603720 != nil:
    section.add "Action", valid_603720
  var valid_603721 = query.getOrDefault("DomainName")
  valid_603721 = validateParameter(valid_603721, JString, required = true,
                                 default = nil)
  if valid_603721 != nil:
    section.add "DomainName", valid_603721
  var valid_603722 = query.getOrDefault("Version")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603722 != nil:
    section.add "Version", valid_603722
  var valid_603723 = query.getOrDefault("SuggesterNames")
  valid_603723 = validateParameter(valid_603723, JArray, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "SuggesterNames", valid_603723
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
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Content-Sha256", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-SignedHeaders", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Credential")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Credential", valid_603730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_GetDescribeSuggesters_603716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_GetDescribeSuggesters_603716; DomainName: string;
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
  var query_603733 = newJObject()
  add(query_603733, "Deployed", newJBool(Deployed))
  add(query_603733, "Action", newJString(Action))
  add(query_603733, "DomainName", newJString(DomainName))
  add(query_603733, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_603733.add "SuggesterNames", SuggesterNames
  result = call_603732.call(nil, query_603733, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_603716(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_603717, base: "/",
    url: url_GetDescribeSuggesters_603718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_603769 = ref object of OpenApiRestCall_602466
proc url_PostIndexDocuments_603771(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_603770(path: JsonNode; query: JsonNode;
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
  var valid_603772 = query.getOrDefault("Action")
  valid_603772 = validateParameter(valid_603772, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_603772 != nil:
    section.add "Action", valid_603772
  var valid_603773 = query.getOrDefault("Version")
  valid_603773 = validateParameter(valid_603773, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603773 != nil:
    section.add "Version", valid_603773
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
  var valid_603774 = header.getOrDefault("X-Amz-Date")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Date", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Security-Token")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Security-Token", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Content-Sha256", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Algorithm")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Algorithm", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Signature")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Signature", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-SignedHeaders", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Credential")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Credential", valid_603780
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603781 = formData.getOrDefault("DomainName")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = nil)
  if valid_603781 != nil:
    section.add "DomainName", valid_603781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603782: Call_PostIndexDocuments_603769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_603782.validator(path, query, header, formData, body)
  let scheme = call_603782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603782.url(scheme.get, call_603782.host, call_603782.base,
                         call_603782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603782, url, valid)

proc call*(call_603783: Call_PostIndexDocuments_603769; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603784 = newJObject()
  var formData_603785 = newJObject()
  add(formData_603785, "DomainName", newJString(DomainName))
  add(query_603784, "Action", newJString(Action))
  add(query_603784, "Version", newJString(Version))
  result = call_603783.call(nil, query_603784, nil, formData_603785, nil)

var postIndexDocuments* = Call_PostIndexDocuments_603769(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_603770, base: "/",
    url: url_PostIndexDocuments_603771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_603753 = ref object of OpenApiRestCall_602466
proc url_GetIndexDocuments_603755(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_603754(path: JsonNode; query: JsonNode;
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
  var valid_603756 = query.getOrDefault("Action")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_603756 != nil:
    section.add "Action", valid_603756
  var valid_603757 = query.getOrDefault("DomainName")
  valid_603757 = validateParameter(valid_603757, JString, required = true,
                                 default = nil)
  if valid_603757 != nil:
    section.add "DomainName", valid_603757
  var valid_603758 = query.getOrDefault("Version")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603758 != nil:
    section.add "Version", valid_603758
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
  var valid_603759 = header.getOrDefault("X-Amz-Date")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Date", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Security-Token")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Security-Token", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Content-Sha256", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Algorithm")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Algorithm", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Signature")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Signature", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-SignedHeaders", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_GetIndexDocuments_603753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_GetIndexDocuments_603753; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_603768 = newJObject()
  add(query_603768, "Action", newJString(Action))
  add(query_603768, "DomainName", newJString(DomainName))
  add(query_603768, "Version", newJString(Version))
  result = call_603767.call(nil, query_603768, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_603753(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_603754,
    base: "/", url: url_GetIndexDocuments_603755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_603801 = ref object of OpenApiRestCall_602466
proc url_PostListDomainNames_603803(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomainNames_603802(path: JsonNode; query: JsonNode;
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
  var valid_603804 = query.getOrDefault("Action")
  valid_603804 = validateParameter(valid_603804, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_603804 != nil:
    section.add "Action", valid_603804
  var valid_603805 = query.getOrDefault("Version")
  valid_603805 = validateParameter(valid_603805, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603805 != nil:
    section.add "Version", valid_603805
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
  var valid_603806 = header.getOrDefault("X-Amz-Date")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Date", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Security-Token")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Security-Token", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Content-Sha256", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Algorithm")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Algorithm", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Signature")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Signature", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-SignedHeaders", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Credential")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Credential", valid_603812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603813: Call_PostListDomainNames_603801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_603813.validator(path, query, header, formData, body)
  let scheme = call_603813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603813.url(scheme.get, call_603813.host, call_603813.base,
                         call_603813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603813, url, valid)

proc call*(call_603814: Call_PostListDomainNames_603801;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603815 = newJObject()
  add(query_603815, "Action", newJString(Action))
  add(query_603815, "Version", newJString(Version))
  result = call_603814.call(nil, query_603815, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_603801(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_603802, base: "/",
    url: url_PostListDomainNames_603803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_603786 = ref object of OpenApiRestCall_602466
proc url_GetListDomainNames_603788(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomainNames_603787(path: JsonNode; query: JsonNode;
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
  var valid_603789 = query.getOrDefault("Action")
  valid_603789 = validateParameter(valid_603789, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_603789 != nil:
    section.add "Action", valid_603789
  var valid_603790 = query.getOrDefault("Version")
  valid_603790 = validateParameter(valid_603790, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603790 != nil:
    section.add "Version", valid_603790
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
  var valid_603791 = header.getOrDefault("X-Amz-Date")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Date", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Security-Token")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Security-Token", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Content-Sha256", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Algorithm")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Algorithm", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Signature")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Signature", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-SignedHeaders", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Credential")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Credential", valid_603797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603798: Call_GetListDomainNames_603786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_603798.validator(path, query, header, formData, body)
  let scheme = call_603798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603798.url(scheme.get, call_603798.host, call_603798.base,
                         call_603798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603798, url, valid)

proc call*(call_603799: Call_GetListDomainNames_603786;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603800 = newJObject()
  add(query_603800, "Action", newJString(Action))
  add(query_603800, "Version", newJString(Version))
  result = call_603799.call(nil, query_603800, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_603786(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_603787, base: "/",
    url: url_GetListDomainNames_603788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_603833 = ref object of OpenApiRestCall_602466
proc url_PostUpdateAvailabilityOptions_603835(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = query.getOrDefault("Action")
  valid_603836 = validateParameter(valid_603836, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_603836 != nil:
    section.add "Action", valid_603836
  var valid_603837 = query.getOrDefault("Version")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603837 != nil:
    section.add "Version", valid_603837
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
  var valid_603838 = header.getOrDefault("X-Amz-Date")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Date", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Security-Token")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Security-Token", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Content-Sha256", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Algorithm")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Algorithm", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Signature")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Signature", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-SignedHeaders", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Credential")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Credential", valid_603844
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603845 = formData.getOrDefault("DomainName")
  valid_603845 = validateParameter(valid_603845, JString, required = true,
                                 default = nil)
  if valid_603845 != nil:
    section.add "DomainName", valid_603845
  var valid_603846 = formData.getOrDefault("MultiAZ")
  valid_603846 = validateParameter(valid_603846, JBool, required = true, default = nil)
  if valid_603846 != nil:
    section.add "MultiAZ", valid_603846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603847: Call_PostUpdateAvailabilityOptions_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603847.validator(path, query, header, formData, body)
  let scheme = call_603847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603847.url(scheme.get, call_603847.host, call_603847.base,
                         call_603847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603847, url, valid)

proc call*(call_603848: Call_PostUpdateAvailabilityOptions_603833;
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
  var query_603849 = newJObject()
  var formData_603850 = newJObject()
  add(formData_603850, "DomainName", newJString(DomainName))
  add(formData_603850, "MultiAZ", newJBool(MultiAZ))
  add(query_603849, "Action", newJString(Action))
  add(query_603849, "Version", newJString(Version))
  result = call_603848.call(nil, query_603849, nil, formData_603850, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_603833(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_603834, base: "/",
    url: url_PostUpdateAvailabilityOptions_603835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_603816 = ref object of OpenApiRestCall_602466
proc url_GetUpdateAvailabilityOptions_603818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_603817(path: JsonNode; query: JsonNode;
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
  var valid_603819 = query.getOrDefault("MultiAZ")
  valid_603819 = validateParameter(valid_603819, JBool, required = true, default = nil)
  if valid_603819 != nil:
    section.add "MultiAZ", valid_603819
  var valid_603820 = query.getOrDefault("Action")
  valid_603820 = validateParameter(valid_603820, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_603820 != nil:
    section.add "Action", valid_603820
  var valid_603821 = query.getOrDefault("DomainName")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = nil)
  if valid_603821 != nil:
    section.add "DomainName", valid_603821
  var valid_603822 = query.getOrDefault("Version")
  valid_603822 = validateParameter(valid_603822, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603822 != nil:
    section.add "Version", valid_603822
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
  var valid_603823 = header.getOrDefault("X-Amz-Date")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Date", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Security-Token")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Security-Token", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Content-Sha256", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Algorithm")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Algorithm", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Signature")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Signature", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-SignedHeaders", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Credential")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Credential", valid_603829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_GetUpdateAvailabilityOptions_603816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_GetUpdateAvailabilityOptions_603816; MultiAZ: bool;
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
  var query_603832 = newJObject()
  add(query_603832, "MultiAZ", newJBool(MultiAZ))
  add(query_603832, "Action", newJString(Action))
  add(query_603832, "DomainName", newJString(DomainName))
  add(query_603832, "Version", newJString(Version))
  result = call_603831.call(nil, query_603832, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_603816(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_603817, base: "/",
    url: url_GetUpdateAvailabilityOptions_603818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_603870 = ref object of OpenApiRestCall_602466
proc url_PostUpdateScalingParameters_603872(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateScalingParameters_603871(path: JsonNode; query: JsonNode;
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
  var valid_603873 = query.getOrDefault("Action")
  valid_603873 = validateParameter(valid_603873, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_603873 != nil:
    section.add "Action", valid_603873
  var valid_603874 = query.getOrDefault("Version")
  valid_603874 = validateParameter(valid_603874, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603874 != nil:
    section.add "Version", valid_603874
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
  var valid_603875 = header.getOrDefault("X-Amz-Date")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Date", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Security-Token")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Security-Token", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Content-Sha256", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Algorithm")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Algorithm", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Signature")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Signature", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-SignedHeaders", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Credential")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Credential", valid_603881
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
  var valid_603882 = formData.getOrDefault("DomainName")
  valid_603882 = validateParameter(valid_603882, JString, required = true,
                                 default = nil)
  if valid_603882 != nil:
    section.add "DomainName", valid_603882
  var valid_603883 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_603883
  var valid_603884 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_603884
  var valid_603885 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_603885
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603886: Call_PostUpdateScalingParameters_603870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603886.validator(path, query, header, formData, body)
  let scheme = call_603886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603886.url(scheme.get, call_603886.host, call_603886.base,
                         call_603886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603886, url, valid)

proc call*(call_603887: Call_PostUpdateScalingParameters_603870;
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
  var query_603888 = newJObject()
  var formData_603889 = newJObject()
  add(formData_603889, "DomainName", newJString(DomainName))
  add(formData_603889, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_603888, "Action", newJString(Action))
  add(formData_603889, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_603889, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_603888, "Version", newJString(Version))
  result = call_603887.call(nil, query_603888, nil, formData_603889, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_603870(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_603871, base: "/",
    url: url_PostUpdateScalingParameters_603872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_603851 = ref object of OpenApiRestCall_602466
proc url_GetUpdateScalingParameters_603853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateScalingParameters_603852(path: JsonNode; query: JsonNode;
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
  var valid_603854 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_603854
  var valid_603855 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_603855
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603856 = query.getOrDefault("Action")
  valid_603856 = validateParameter(valid_603856, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_603856 != nil:
    section.add "Action", valid_603856
  var valid_603857 = query.getOrDefault("DomainName")
  valid_603857 = validateParameter(valid_603857, JString, required = true,
                                 default = nil)
  if valid_603857 != nil:
    section.add "DomainName", valid_603857
  var valid_603858 = query.getOrDefault("Version")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603858 != nil:
    section.add "Version", valid_603858
  var valid_603859 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_603859
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
  var valid_603860 = header.getOrDefault("X-Amz-Date")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Date", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Security-Token")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Security-Token", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Content-Sha256", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Algorithm")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Algorithm", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Signature")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Signature", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-SignedHeaders", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Credential")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Credential", valid_603866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603867: Call_GetUpdateScalingParameters_603851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_603867.validator(path, query, header, formData, body)
  let scheme = call_603867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603867.url(scheme.get, call_603867.host, call_603867.base,
                         call_603867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603867, url, valid)

proc call*(call_603868: Call_GetUpdateScalingParameters_603851; DomainName: string;
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
  var query_603869 = newJObject()
  add(query_603869, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_603869, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_603869, "Action", newJString(Action))
  add(query_603869, "DomainName", newJString(DomainName))
  add(query_603869, "Version", newJString(Version))
  add(query_603869, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_603868.call(nil, query_603869, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_603851(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_603852, base: "/",
    url: url_GetUpdateScalingParameters_603853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_603907 = ref object of OpenApiRestCall_602466
proc url_PostUpdateServiceAccessPolicies_603909(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_603908(path: JsonNode;
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
  var valid_603910 = query.getOrDefault("Action")
  valid_603910 = validateParameter(valid_603910, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_603910 != nil:
    section.add "Action", valid_603910
  var valid_603911 = query.getOrDefault("Version")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603911 != nil:
    section.add "Version", valid_603911
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
  var valid_603912 = header.getOrDefault("X-Amz-Date")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Date", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Security-Token")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Security-Token", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Content-Sha256", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Algorithm")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Algorithm", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Signature")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Signature", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-SignedHeaders", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Credential")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Credential", valid_603918
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
  var valid_603919 = formData.getOrDefault("DomainName")
  valid_603919 = validateParameter(valid_603919, JString, required = true,
                                 default = nil)
  if valid_603919 != nil:
    section.add "DomainName", valid_603919
  var valid_603920 = formData.getOrDefault("AccessPolicies")
  valid_603920 = validateParameter(valid_603920, JString, required = true,
                                 default = nil)
  if valid_603920 != nil:
    section.add "AccessPolicies", valid_603920
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603921: Call_PostUpdateServiceAccessPolicies_603907;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_603921.validator(path, query, header, formData, body)
  let scheme = call_603921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603921.url(scheme.get, call_603921.host, call_603921.base,
                         call_603921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603921, url, valid)

proc call*(call_603922: Call_PostUpdateServiceAccessPolicies_603907;
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
  var query_603923 = newJObject()
  var formData_603924 = newJObject()
  add(formData_603924, "DomainName", newJString(DomainName))
  add(formData_603924, "AccessPolicies", newJString(AccessPolicies))
  add(query_603923, "Action", newJString(Action))
  add(query_603923, "Version", newJString(Version))
  result = call_603922.call(nil, query_603923, nil, formData_603924, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_603907(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_603908, base: "/",
    url: url_PostUpdateServiceAccessPolicies_603909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_603890 = ref object of OpenApiRestCall_602466
proc url_GetUpdateServiceAccessPolicies_603892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_603891(path: JsonNode;
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
  var valid_603893 = query.getOrDefault("Action")
  valid_603893 = validateParameter(valid_603893, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_603893 != nil:
    section.add "Action", valid_603893
  var valid_603894 = query.getOrDefault("AccessPolicies")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = nil)
  if valid_603894 != nil:
    section.add "AccessPolicies", valid_603894
  var valid_603895 = query.getOrDefault("DomainName")
  valid_603895 = validateParameter(valid_603895, JString, required = true,
                                 default = nil)
  if valid_603895 != nil:
    section.add "DomainName", valid_603895
  var valid_603896 = query.getOrDefault("Version")
  valid_603896 = validateParameter(valid_603896, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_603896 != nil:
    section.add "Version", valid_603896
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
  var valid_603897 = header.getOrDefault("X-Amz-Date")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Date", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Security-Token")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Security-Token", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Content-Sha256", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Algorithm")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Algorithm", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Signature")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Signature", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-SignedHeaders", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Credential")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Credential", valid_603903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603904: Call_GetUpdateServiceAccessPolicies_603890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_603904.validator(path, query, header, formData, body)
  let scheme = call_603904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603904.url(scheme.get, call_603904.host, call_603904.base,
                         call_603904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603904, url, valid)

proc call*(call_603905: Call_GetUpdateServiceAccessPolicies_603890;
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
  var query_603906 = newJObject()
  add(query_603906, "Action", newJString(Action))
  add(query_603906, "AccessPolicies", newJString(AccessPolicies))
  add(query_603906, "DomainName", newJString(DomainName))
  add(query_603906, "Version", newJString(Version))
  result = call_603905.call(nil, query_603906, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_603890(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_603891, base: "/",
    url: url_GetUpdateServiceAccessPolicies_603892,
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
