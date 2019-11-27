
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_599976 = ref object of OpenApiRestCall_599368
proc url_PostBuildSuggesters_599978(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBuildSuggesters_599977(path: JsonNode; query: JsonNode;
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
  var valid_599979 = query.getOrDefault("Action")
  valid_599979 = validateParameter(valid_599979, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_599979 != nil:
    section.add "Action", valid_599979
  var valid_599980 = query.getOrDefault("Version")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_599980 != nil:
    section.add "Version", valid_599980
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
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_599988 = formData.getOrDefault("DomainName")
  valid_599988 = validateParameter(valid_599988, JString, required = true,
                                 default = nil)
  if valid_599988 != nil:
    section.add "DomainName", valid_599988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599989: Call_PostBuildSuggesters_599976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_599989.validator(path, query, header, formData, body)
  let scheme = call_599989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599989.url(scheme.get, call_599989.host, call_599989.base,
                         call_599989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599989, url, valid)

proc call*(call_599990: Call_PostBuildSuggesters_599976; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_599991 = newJObject()
  var formData_599992 = newJObject()
  add(formData_599992, "DomainName", newJString(DomainName))
  add(query_599991, "Action", newJString(Action))
  add(query_599991, "Version", newJString(Version))
  result = call_599990.call(nil, query_599991, nil, formData_599992, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_599976(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_599977, base: "/",
    url: url_PostBuildSuggesters_599978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_599705 = ref object of OpenApiRestCall_599368
proc url_GetBuildSuggesters_599707(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuildSuggesters_599706(path: JsonNode; query: JsonNode;
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
  var valid_599832 = query.getOrDefault("Action")
  valid_599832 = validateParameter(valid_599832, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_599832 != nil:
    section.add "Action", valid_599832
  var valid_599833 = query.getOrDefault("DomainName")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "DomainName", valid_599833
  var valid_599834 = query.getOrDefault("Version")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_599834 != nil:
    section.add "Version", valid_599834
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
  var valid_599835 = header.getOrDefault("X-Amz-Date")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Date", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Security-Token")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Security-Token", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_GetBuildSuggesters_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_GetBuildSuggesters_599705; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_599936 = newJObject()
  add(query_599936, "Action", newJString(Action))
  add(query_599936, "DomainName", newJString(DomainName))
  add(query_599936, "Version", newJString(Version))
  result = call_599935.call(nil, query_599936, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_599705(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_599706, base: "/",
    url: url_GetBuildSuggesters_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_600009 = ref object of OpenApiRestCall_599368
proc url_PostCreateDomain_600011(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_600010(path: JsonNode; query: JsonNode;
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
  var valid_600012 = query.getOrDefault("Action")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_600012 != nil:
    section.add "Action", valid_600012
  var valid_600013 = query.getOrDefault("Version")
  valid_600013 = validateParameter(valid_600013, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600013 != nil:
    section.add "Version", valid_600013
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
  var valid_600014 = header.getOrDefault("X-Amz-Date")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Date", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Security-Token")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Security-Token", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Content-Sha256", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Algorithm")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Algorithm", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Signature")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Signature", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-SignedHeaders", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Credential")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Credential", valid_600020
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600021 = formData.getOrDefault("DomainName")
  valid_600021 = validateParameter(valid_600021, JString, required = true,
                                 default = nil)
  if valid_600021 != nil:
    section.add "DomainName", valid_600021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600022: Call_PostCreateDomain_600009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600022.validator(path, query, header, formData, body)
  let scheme = call_600022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600022.url(scheme.get, call_600022.host, call_600022.base,
                         call_600022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600022, url, valid)

proc call*(call_600023: Call_PostCreateDomain_600009; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600024 = newJObject()
  var formData_600025 = newJObject()
  add(formData_600025, "DomainName", newJString(DomainName))
  add(query_600024, "Action", newJString(Action))
  add(query_600024, "Version", newJString(Version))
  result = call_600023.call(nil, query_600024, nil, formData_600025, nil)

var postCreateDomain* = Call_PostCreateDomain_600009(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_600010,
    base: "/", url: url_PostCreateDomain_600011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_599993 = ref object of OpenApiRestCall_599368
proc url_GetCreateDomain_599995(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_599994(path: JsonNode; query: JsonNode;
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
  var valid_599996 = query.getOrDefault("Action")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_599996 != nil:
    section.add "Action", valid_599996
  var valid_599997 = query.getOrDefault("DomainName")
  valid_599997 = validateParameter(valid_599997, JString, required = true,
                                 default = nil)
  if valid_599997 != nil:
    section.add "DomainName", valid_599997
  var valid_599998 = query.getOrDefault("Version")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_599998 != nil:
    section.add "Version", valid_599998
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
  var valid_599999 = header.getOrDefault("X-Amz-Date")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Date", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Security-Token")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Security-Token", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Content-Sha256", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Algorithm")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Algorithm", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Signature")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Signature", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-SignedHeaders", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_GetCreateDomain_599993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_GetCreateDomain_599993; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600008 = newJObject()
  add(query_600008, "Action", newJString(Action))
  add(query_600008, "DomainName", newJString(DomainName))
  add(query_600008, "Version", newJString(Version))
  result = call_600007.call(nil, query_600008, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_599993(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_599994,
    base: "/", url: url_GetCreateDomain_599995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_600045 = ref object of OpenApiRestCall_599368
proc url_PostDefineAnalysisScheme_600047(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineAnalysisScheme_600046(path: JsonNode; query: JsonNode;
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
  var valid_600048 = query.getOrDefault("Action")
  valid_600048 = validateParameter(valid_600048, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_600048 != nil:
    section.add "Action", valid_600048
  var valid_600049 = query.getOrDefault("Version")
  valid_600049 = validateParameter(valid_600049, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600049 != nil:
    section.add "Version", valid_600049
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
  var valid_600050 = header.getOrDefault("X-Amz-Date")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Date", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Security-Token")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Security-Token", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Content-Sha256", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Algorithm")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Algorithm", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Signature")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Signature", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-SignedHeaders", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Credential")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Credential", valid_600056
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
  var valid_600057 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_600057
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600058 = formData.getOrDefault("DomainName")
  valid_600058 = validateParameter(valid_600058, JString, required = true,
                                 default = nil)
  if valid_600058 != nil:
    section.add "DomainName", valid_600058
  var valid_600059 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_600059
  var valid_600060 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_600060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_PostDefineAnalysisScheme_600045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_PostDefineAnalysisScheme_600045; DomainName: string;
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
  var query_600063 = newJObject()
  var formData_600064 = newJObject()
  add(formData_600064, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_600064, "DomainName", newJString(DomainName))
  add(formData_600064, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_600063, "Action", newJString(Action))
  add(formData_600064, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_600063, "Version", newJString(Version))
  result = call_600062.call(nil, query_600063, nil, formData_600064, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_600045(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_600046, base: "/",
    url: url_PostDefineAnalysisScheme_600047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_600026 = ref object of OpenApiRestCall_599368
proc url_GetDefineAnalysisScheme_600028(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineAnalysisScheme_600027(path: JsonNode; query: JsonNode;
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
  var valid_600029 = query.getOrDefault("Action")
  valid_600029 = validateParameter(valid_600029, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_600029 != nil:
    section.add "Action", valid_600029
  var valid_600030 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_600030
  var valid_600031 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_600031
  var valid_600032 = query.getOrDefault("DomainName")
  valid_600032 = validateParameter(valid_600032, JString, required = true,
                                 default = nil)
  if valid_600032 != nil:
    section.add "DomainName", valid_600032
  var valid_600033 = query.getOrDefault("Version")
  valid_600033 = validateParameter(valid_600033, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600033 != nil:
    section.add "Version", valid_600033
  var valid_600034 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_600034
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
  var valid_600035 = header.getOrDefault("X-Amz-Date")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Date", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Security-Token")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Security-Token", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Content-Sha256", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Algorithm")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Algorithm", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Signature")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Signature", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-SignedHeaders", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Credential")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Credential", valid_600041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600042: Call_GetDefineAnalysisScheme_600026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600042.validator(path, query, header, formData, body)
  let scheme = call_600042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600042.url(scheme.get, call_600042.host, call_600042.base,
                         call_600042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600042, url, valid)

proc call*(call_600043: Call_GetDefineAnalysisScheme_600026; DomainName: string;
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
  var query_600044 = newJObject()
  add(query_600044, "Action", newJString(Action))
  add(query_600044, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_600044, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_600044, "DomainName", newJString(DomainName))
  add(query_600044, "Version", newJString(Version))
  add(query_600044, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_600043.call(nil, query_600044, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_600026(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_600027, base: "/",
    url: url_GetDefineAnalysisScheme_600028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_600083 = ref object of OpenApiRestCall_599368
proc url_PostDefineExpression_600085(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineExpression_600084(path: JsonNode; query: JsonNode;
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
  var valid_600086 = query.getOrDefault("Action")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_600086 != nil:
    section.add "Action", valid_600086
  var valid_600087 = query.getOrDefault("Version")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600087 != nil:
    section.add "Version", valid_600087
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
  var valid_600088 = header.getOrDefault("X-Amz-Date")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Date", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Security-Token")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Security-Token", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Content-Sha256", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Algorithm")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Algorithm", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Signature", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-SignedHeaders", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Credential")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Credential", valid_600094
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
  var valid_600095 = formData.getOrDefault("DomainName")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = nil)
  if valid_600095 != nil:
    section.add "DomainName", valid_600095
  var valid_600096 = formData.getOrDefault("Expression.ExpressionName")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "Expression.ExpressionName", valid_600096
  var valid_600097 = formData.getOrDefault("Expression.ExpressionValue")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "Expression.ExpressionValue", valid_600097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600098: Call_PostDefineExpression_600083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600098.validator(path, query, header, formData, body)
  let scheme = call_600098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600098.url(scheme.get, call_600098.host, call_600098.base,
                         call_600098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600098, url, valid)

proc call*(call_600099: Call_PostDefineExpression_600083; DomainName: string;
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
  var query_600100 = newJObject()
  var formData_600101 = newJObject()
  add(formData_600101, "DomainName", newJString(DomainName))
  add(formData_600101, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_600101, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_600100, "Action", newJString(Action))
  add(query_600100, "Version", newJString(Version))
  result = call_600099.call(nil, query_600100, nil, formData_600101, nil)

var postDefineExpression* = Call_PostDefineExpression_600083(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_600084, base: "/",
    url: url_PostDefineExpression_600085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_600065 = ref object of OpenApiRestCall_599368
proc url_GetDefineExpression_600067(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineExpression_600066(path: JsonNode; query: JsonNode;
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
  var valid_600068 = query.getOrDefault("Action")
  valid_600068 = validateParameter(valid_600068, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_600068 != nil:
    section.add "Action", valid_600068
  var valid_600069 = query.getOrDefault("Expression.ExpressionValue")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "Expression.ExpressionValue", valid_600069
  var valid_600070 = query.getOrDefault("Expression.ExpressionName")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "Expression.ExpressionName", valid_600070
  var valid_600071 = query.getOrDefault("DomainName")
  valid_600071 = validateParameter(valid_600071, JString, required = true,
                                 default = nil)
  if valid_600071 != nil:
    section.add "DomainName", valid_600071
  var valid_600072 = query.getOrDefault("Version")
  valid_600072 = validateParameter(valid_600072, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600072 != nil:
    section.add "Version", valid_600072
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
  var valid_600073 = header.getOrDefault("X-Amz-Date")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Date", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Security-Token")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Security-Token", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Content-Sha256", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Algorithm")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Algorithm", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Signature")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Signature", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-SignedHeaders", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Credential")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Credential", valid_600079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600080: Call_GetDefineExpression_600065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600080.validator(path, query, header, formData, body)
  let scheme = call_600080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600080.url(scheme.get, call_600080.host, call_600080.base,
                         call_600080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600080, url, valid)

proc call*(call_600081: Call_GetDefineExpression_600065; DomainName: string;
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
  var query_600082 = newJObject()
  add(query_600082, "Action", newJString(Action))
  add(query_600082, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_600082, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_600082, "DomainName", newJString(DomainName))
  add(query_600082, "Version", newJString(Version))
  result = call_600081.call(nil, query_600082, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_600065(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_600066, base: "/",
    url: url_GetDefineExpression_600067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_600131 = ref object of OpenApiRestCall_599368
proc url_PostDefineIndexField_600133(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_600132(path: JsonNode; query: JsonNode;
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
  var valid_600134 = query.getOrDefault("Action")
  valid_600134 = validateParameter(valid_600134, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_600134 != nil:
    section.add "Action", valid_600134
  var valid_600135 = query.getOrDefault("Version")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600135 != nil:
    section.add "Version", valid_600135
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
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
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
  var valid_600143 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "IndexField.TextArrayOptions", valid_600143
  var valid_600144 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "IndexField.DateArrayOptions", valid_600144
  var valid_600145 = formData.getOrDefault("IndexField.TextOptions")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "IndexField.TextOptions", valid_600145
  var valid_600146 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "IndexField.DoubleOptions", valid_600146
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600147 = formData.getOrDefault("DomainName")
  valid_600147 = validateParameter(valid_600147, JString, required = true,
                                 default = nil)
  if valid_600147 != nil:
    section.add "DomainName", valid_600147
  var valid_600148 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "IndexField.LiteralOptions", valid_600148
  var valid_600149 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_600149
  var valid_600150 = formData.getOrDefault("IndexField.DateOptions")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "IndexField.DateOptions", valid_600150
  var valid_600151 = formData.getOrDefault("IndexField.IntOptions")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "IndexField.IntOptions", valid_600151
  var valid_600152 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "IndexField.LatLonOptions", valid_600152
  var valid_600153 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "IndexField.IndexFieldType", valid_600153
  var valid_600154 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_600154
  var valid_600155 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "IndexField.IndexFieldName", valid_600155
  var valid_600156 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "IndexField.IntArrayOptions", valid_600156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600157: Call_PostDefineIndexField_600131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600157.validator(path, query, header, formData, body)
  let scheme = call_600157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600157.url(scheme.get, call_600157.host, call_600157.base,
                         call_600157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600157, url, valid)

proc call*(call_600158: Call_PostDefineIndexField_600131; DomainName: string;
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
  var query_600159 = newJObject()
  var formData_600160 = newJObject()
  add(formData_600160, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_600160, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_600160, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_600160, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_600160, "DomainName", newJString(DomainName))
  add(formData_600160, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_600160, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_600160, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_600160, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_600160, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_600160, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_600159, "Action", newJString(Action))
  add(formData_600160, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_600160, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_600159, "Version", newJString(Version))
  add(formData_600160, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_600158.call(nil, query_600159, nil, formData_600160, nil)

var postDefineIndexField* = Call_PostDefineIndexField_600131(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_600132, base: "/",
    url: url_PostDefineIndexField_600133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_600102 = ref object of OpenApiRestCall_599368
proc url_GetDefineIndexField_600104(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_600103(path: JsonNode; query: JsonNode;
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
  var valid_600105 = query.getOrDefault("IndexField.TextOptions")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "IndexField.TextOptions", valid_600105
  var valid_600106 = query.getOrDefault("IndexField.DateOptions")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "IndexField.DateOptions", valid_600106
  var valid_600107 = query.getOrDefault("IndexField.LiteralOptions")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "IndexField.LiteralOptions", valid_600107
  var valid_600108 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_600108
  var valid_600109 = query.getOrDefault("IndexField.IndexFieldType")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "IndexField.IndexFieldType", valid_600109
  var valid_600110 = query.getOrDefault("IndexField.IntOptions")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "IndexField.IntOptions", valid_600110
  var valid_600111 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "IndexField.DateArrayOptions", valid_600111
  var valid_600112 = query.getOrDefault("IndexField.DoubleOptions")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "IndexField.DoubleOptions", valid_600112
  var valid_600113 = query.getOrDefault("IndexField.IndexFieldName")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "IndexField.IndexFieldName", valid_600113
  var valid_600114 = query.getOrDefault("IndexField.LatLonOptions")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "IndexField.LatLonOptions", valid_600114
  var valid_600115 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "IndexField.IntArrayOptions", valid_600115
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600116 = query.getOrDefault("Action")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_600116 != nil:
    section.add "Action", valid_600116
  var valid_600117 = query.getOrDefault("DomainName")
  valid_600117 = validateParameter(valid_600117, JString, required = true,
                                 default = nil)
  if valid_600117 != nil:
    section.add "DomainName", valid_600117
  var valid_600118 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "IndexField.TextArrayOptions", valid_600118
  var valid_600119 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_600119
  var valid_600120 = query.getOrDefault("Version")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600120 != nil:
    section.add "Version", valid_600120
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
  var valid_600121 = header.getOrDefault("X-Amz-Date")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Date", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Security-Token")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Security-Token", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Content-Sha256", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Algorithm")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Algorithm", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Signature")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Signature", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-SignedHeaders", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Credential")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Credential", valid_600127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_GetDefineIndexField_600102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_GetDefineIndexField_600102; DomainName: string;
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
  var query_600130 = newJObject()
  add(query_600130, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_600130, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_600130, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_600130, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_600130, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_600130, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_600130, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_600130, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_600130, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_600130, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_600130, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_600130, "Action", newJString(Action))
  add(query_600130, "DomainName", newJString(DomainName))
  add(query_600130, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_600130, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_600130, "Version", newJString(Version))
  result = call_600129.call(nil, query_600130, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_600102(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_600103, base: "/",
    url: url_GetDefineIndexField_600104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_600179 = ref object of OpenApiRestCall_599368
proc url_PostDefineSuggester_600181(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineSuggester_600180(path: JsonNode; query: JsonNode;
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
  var valid_600182 = query.getOrDefault("Action")
  valid_600182 = validateParameter(valid_600182, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_600182 != nil:
    section.add "Action", valid_600182
  var valid_600183 = query.getOrDefault("Version")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600183 != nil:
    section.add "Version", valid_600183
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
  var valid_600184 = header.getOrDefault("X-Amz-Date")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Date", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Security-Token")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Security-Token", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Content-Sha256", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Algorithm")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Algorithm", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Signature")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Signature", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-SignedHeaders", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Credential")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Credential", valid_600190
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
  var valid_600191 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_600191
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600192 = formData.getOrDefault("DomainName")
  valid_600192 = validateParameter(valid_600192, JString, required = true,
                                 default = nil)
  if valid_600192 != nil:
    section.add "DomainName", valid_600192
  var valid_600193 = formData.getOrDefault("Suggester.SuggesterName")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "Suggester.SuggesterName", valid_600193
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_PostDefineSuggester_600179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_PostDefineSuggester_600179; DomainName: string;
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
  var query_600196 = newJObject()
  var formData_600197 = newJObject()
  add(formData_600197, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_600197, "DomainName", newJString(DomainName))
  add(query_600196, "Action", newJString(Action))
  add(query_600196, "Version", newJString(Version))
  add(formData_600197, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_600195.call(nil, query_600196, nil, formData_600197, nil)

var postDefineSuggester* = Call_PostDefineSuggester_600179(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_600180, base: "/",
    url: url_PostDefineSuggester_600181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_600161 = ref object of OpenApiRestCall_599368
proc url_GetDefineSuggester_600163(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineSuggester_600162(path: JsonNode; query: JsonNode;
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
  var valid_600164 = query.getOrDefault("Suggester.SuggesterName")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "Suggester.SuggesterName", valid_600164
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600165 = query.getOrDefault("Action")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_600165 != nil:
    section.add "Action", valid_600165
  var valid_600166 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_600166
  var valid_600167 = query.getOrDefault("DomainName")
  valid_600167 = validateParameter(valid_600167, JString, required = true,
                                 default = nil)
  if valid_600167 != nil:
    section.add "DomainName", valid_600167
  var valid_600168 = query.getOrDefault("Version")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600168 != nil:
    section.add "Version", valid_600168
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
  var valid_600169 = header.getOrDefault("X-Amz-Date")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Date", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Security-Token")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Security-Token", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Content-Sha256", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Algorithm")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Algorithm", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Signature")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Signature", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-SignedHeaders", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Credential")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Credential", valid_600175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600176: Call_GetDefineSuggester_600161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600176.validator(path, query, header, formData, body)
  let scheme = call_600176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600176.url(scheme.get, call_600176.host, call_600176.base,
                         call_600176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600176, url, valid)

proc call*(call_600177: Call_GetDefineSuggester_600161; DomainName: string;
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
  var query_600178 = newJObject()
  add(query_600178, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_600178, "Action", newJString(Action))
  add(query_600178, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_600178, "DomainName", newJString(DomainName))
  add(query_600178, "Version", newJString(Version))
  result = call_600177.call(nil, query_600178, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_600161(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_600162, base: "/",
    url: url_GetDefineSuggester_600163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_600215 = ref object of OpenApiRestCall_599368
proc url_PostDeleteAnalysisScheme_600217(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnalysisScheme_600216(path: JsonNode; query: JsonNode;
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
  var valid_600218 = query.getOrDefault("Action")
  valid_600218 = validateParameter(valid_600218, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_600218 != nil:
    section.add "Action", valid_600218
  var valid_600219 = query.getOrDefault("Version")
  valid_600219 = validateParameter(valid_600219, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600219 != nil:
    section.add "Version", valid_600219
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
  var valid_600220 = header.getOrDefault("X-Amz-Date")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Date", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Security-Token")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Security-Token", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Content-Sha256", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Algorithm")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Algorithm", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Signature")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Signature", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-SignedHeaders", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Credential")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Credential", valid_600226
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600227 = formData.getOrDefault("DomainName")
  valid_600227 = validateParameter(valid_600227, JString, required = true,
                                 default = nil)
  if valid_600227 != nil:
    section.add "DomainName", valid_600227
  var valid_600228 = formData.getOrDefault("AnalysisSchemeName")
  valid_600228 = validateParameter(valid_600228, JString, required = true,
                                 default = nil)
  if valid_600228 != nil:
    section.add "AnalysisSchemeName", valid_600228
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600229: Call_PostDeleteAnalysisScheme_600215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600229.validator(path, query, header, formData, body)
  let scheme = call_600229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600229.url(scheme.get, call_600229.host, call_600229.base,
                         call_600229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600229, url, valid)

proc call*(call_600230: Call_PostDeleteAnalysisScheme_600215; DomainName: string;
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
  var query_600231 = newJObject()
  var formData_600232 = newJObject()
  add(formData_600232, "DomainName", newJString(DomainName))
  add(formData_600232, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_600231, "Action", newJString(Action))
  add(query_600231, "Version", newJString(Version))
  result = call_600230.call(nil, query_600231, nil, formData_600232, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_600215(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_600216, base: "/",
    url: url_PostDeleteAnalysisScheme_600217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_600198 = ref object of OpenApiRestCall_599368
proc url_GetDeleteAnalysisScheme_600200(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnalysisScheme_600199(path: JsonNode; query: JsonNode;
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
  var valid_600201 = query.getOrDefault("Action")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_600201 != nil:
    section.add "Action", valid_600201
  var valid_600202 = query.getOrDefault("DomainName")
  valid_600202 = validateParameter(valid_600202, JString, required = true,
                                 default = nil)
  if valid_600202 != nil:
    section.add "DomainName", valid_600202
  var valid_600203 = query.getOrDefault("AnalysisSchemeName")
  valid_600203 = validateParameter(valid_600203, JString, required = true,
                                 default = nil)
  if valid_600203 != nil:
    section.add "AnalysisSchemeName", valid_600203
  var valid_600204 = query.getOrDefault("Version")
  valid_600204 = validateParameter(valid_600204, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600204 != nil:
    section.add "Version", valid_600204
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
  var valid_600205 = header.getOrDefault("X-Amz-Date")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Date", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Security-Token")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Security-Token", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Content-Sha256", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Algorithm")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Algorithm", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Signature")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Signature", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-SignedHeaders", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Credential")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Credential", valid_600211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600212: Call_GetDeleteAnalysisScheme_600198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_GetDeleteAnalysisScheme_600198; DomainName: string;
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
  var query_600214 = newJObject()
  add(query_600214, "Action", newJString(Action))
  add(query_600214, "DomainName", newJString(DomainName))
  add(query_600214, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_600214, "Version", newJString(Version))
  result = call_600213.call(nil, query_600214, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_600198(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_600199, base: "/",
    url: url_GetDeleteAnalysisScheme_600200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_600249 = ref object of OpenApiRestCall_599368
proc url_PostDeleteDomain_600251(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_600250(path: JsonNode; query: JsonNode;
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
  var valid_600252 = query.getOrDefault("Action")
  valid_600252 = validateParameter(valid_600252, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600252 != nil:
    section.add "Action", valid_600252
  var valid_600253 = query.getOrDefault("Version")
  valid_600253 = validateParameter(valid_600253, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600253 != nil:
    section.add "Version", valid_600253
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
  var valid_600254 = header.getOrDefault("X-Amz-Date")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Date", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Security-Token")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Security-Token", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Content-Sha256", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Algorithm")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Algorithm", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Signature")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Signature", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-SignedHeaders", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Credential")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Credential", valid_600260
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600261 = formData.getOrDefault("DomainName")
  valid_600261 = validateParameter(valid_600261, JString, required = true,
                                 default = nil)
  if valid_600261 != nil:
    section.add "DomainName", valid_600261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600262: Call_PostDeleteDomain_600249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600262.validator(path, query, header, formData, body)
  let scheme = call_600262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600262.url(scheme.get, call_600262.host, call_600262.base,
                         call_600262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600262, url, valid)

proc call*(call_600263: Call_PostDeleteDomain_600249; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600264 = newJObject()
  var formData_600265 = newJObject()
  add(formData_600265, "DomainName", newJString(DomainName))
  add(query_600264, "Action", newJString(Action))
  add(query_600264, "Version", newJString(Version))
  result = call_600263.call(nil, query_600264, nil, formData_600265, nil)

var postDeleteDomain* = Call_PostDeleteDomain_600249(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_600250,
    base: "/", url: url_PostDeleteDomain_600251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_600233 = ref object of OpenApiRestCall_599368
proc url_GetDeleteDomain_600235(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_600234(path: JsonNode; query: JsonNode;
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
  var valid_600236 = query.getOrDefault("Action")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600236 != nil:
    section.add "Action", valid_600236
  var valid_600237 = query.getOrDefault("DomainName")
  valid_600237 = validateParameter(valid_600237, JString, required = true,
                                 default = nil)
  if valid_600237 != nil:
    section.add "DomainName", valid_600237
  var valid_600238 = query.getOrDefault("Version")
  valid_600238 = validateParameter(valid_600238, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600238 != nil:
    section.add "Version", valid_600238
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
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Content-Sha256", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Algorithm")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Algorithm", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Signature")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Signature", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-SignedHeaders", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Credential")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Credential", valid_600245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600246: Call_GetDeleteDomain_600233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600246.validator(path, query, header, formData, body)
  let scheme = call_600246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600246.url(scheme.get, call_600246.host, call_600246.base,
                         call_600246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600246, url, valid)

proc call*(call_600247: Call_GetDeleteDomain_600233; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600248 = newJObject()
  add(query_600248, "Action", newJString(Action))
  add(query_600248, "DomainName", newJString(DomainName))
  add(query_600248, "Version", newJString(Version))
  result = call_600247.call(nil, query_600248, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_600233(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_600234,
    base: "/", url: url_GetDeleteDomain_600235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_600283 = ref object of OpenApiRestCall_599368
proc url_PostDeleteExpression_600285(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteExpression_600284(path: JsonNode; query: JsonNode;
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
  var valid_600286 = query.getOrDefault("Action")
  valid_600286 = validateParameter(valid_600286, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_600286 != nil:
    section.add "Action", valid_600286
  var valid_600287 = query.getOrDefault("Version")
  valid_600287 = validateParameter(valid_600287, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600287 != nil:
    section.add "Version", valid_600287
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
  var valid_600288 = header.getOrDefault("X-Amz-Date")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Date", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Security-Token")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Security-Token", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Content-Sha256", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Algorithm")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Algorithm", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Signature")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Signature", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-SignedHeaders", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Credential")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Credential", valid_600294
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_600295 = formData.getOrDefault("ExpressionName")
  valid_600295 = validateParameter(valid_600295, JString, required = true,
                                 default = nil)
  if valid_600295 != nil:
    section.add "ExpressionName", valid_600295
  var valid_600296 = formData.getOrDefault("DomainName")
  valid_600296 = validateParameter(valid_600296, JString, required = true,
                                 default = nil)
  if valid_600296 != nil:
    section.add "DomainName", valid_600296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600297: Call_PostDeleteExpression_600283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600297.validator(path, query, header, formData, body)
  let scheme = call_600297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600297.url(scheme.get, call_600297.host, call_600297.base,
                         call_600297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600297, url, valid)

proc call*(call_600298: Call_PostDeleteExpression_600283; ExpressionName: string;
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
  var query_600299 = newJObject()
  var formData_600300 = newJObject()
  add(formData_600300, "ExpressionName", newJString(ExpressionName))
  add(formData_600300, "DomainName", newJString(DomainName))
  add(query_600299, "Action", newJString(Action))
  add(query_600299, "Version", newJString(Version))
  result = call_600298.call(nil, query_600299, nil, formData_600300, nil)

var postDeleteExpression* = Call_PostDeleteExpression_600283(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_600284, base: "/",
    url: url_PostDeleteExpression_600285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_600266 = ref object of OpenApiRestCall_599368
proc url_GetDeleteExpression_600268(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteExpression_600267(path: JsonNode; query: JsonNode;
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
  var valid_600269 = query.getOrDefault("Action")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_600269 != nil:
    section.add "Action", valid_600269
  var valid_600270 = query.getOrDefault("ExpressionName")
  valid_600270 = validateParameter(valid_600270, JString, required = true,
                                 default = nil)
  if valid_600270 != nil:
    section.add "ExpressionName", valid_600270
  var valid_600271 = query.getOrDefault("DomainName")
  valid_600271 = validateParameter(valid_600271, JString, required = true,
                                 default = nil)
  if valid_600271 != nil:
    section.add "DomainName", valid_600271
  var valid_600272 = query.getOrDefault("Version")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600272 != nil:
    section.add "Version", valid_600272
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
  var valid_600273 = header.getOrDefault("X-Amz-Date")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Date", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Security-Token")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Security-Token", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Content-Sha256", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Algorithm")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Algorithm", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Signature")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Signature", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-SignedHeaders", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Credential")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Credential", valid_600279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600280: Call_GetDeleteExpression_600266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600280.validator(path, query, header, formData, body)
  let scheme = call_600280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600280.url(scheme.get, call_600280.host, call_600280.base,
                         call_600280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600280, url, valid)

proc call*(call_600281: Call_GetDeleteExpression_600266; ExpressionName: string;
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
  var query_600282 = newJObject()
  add(query_600282, "Action", newJString(Action))
  add(query_600282, "ExpressionName", newJString(ExpressionName))
  add(query_600282, "DomainName", newJString(DomainName))
  add(query_600282, "Version", newJString(Version))
  result = call_600281.call(nil, query_600282, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_600266(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_600267, base: "/",
    url: url_GetDeleteExpression_600268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_600318 = ref object of OpenApiRestCall_599368
proc url_PostDeleteIndexField_600320(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_600319(path: JsonNode; query: JsonNode;
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
  var valid_600321 = query.getOrDefault("Action")
  valid_600321 = validateParameter(valid_600321, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_600321 != nil:
    section.add "Action", valid_600321
  var valid_600322 = query.getOrDefault("Version")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600322 != nil:
    section.add "Version", valid_600322
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
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600330 = formData.getOrDefault("DomainName")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = nil)
  if valid_600330 != nil:
    section.add "DomainName", valid_600330
  var valid_600331 = formData.getOrDefault("IndexFieldName")
  valid_600331 = validateParameter(valid_600331, JString, required = true,
                                 default = nil)
  if valid_600331 != nil:
    section.add "IndexFieldName", valid_600331
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_PostDeleteIndexField_600318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_PostDeleteIndexField_600318; DomainName: string;
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
  var query_600334 = newJObject()
  var formData_600335 = newJObject()
  add(formData_600335, "DomainName", newJString(DomainName))
  add(formData_600335, "IndexFieldName", newJString(IndexFieldName))
  add(query_600334, "Action", newJString(Action))
  add(query_600334, "Version", newJString(Version))
  result = call_600333.call(nil, query_600334, nil, formData_600335, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_600318(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_600319, base: "/",
    url: url_PostDeleteIndexField_600320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_600301 = ref object of OpenApiRestCall_599368
proc url_GetDeleteIndexField_600303(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_600302(path: JsonNode; query: JsonNode;
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
  var valid_600304 = query.getOrDefault("IndexFieldName")
  valid_600304 = validateParameter(valid_600304, JString, required = true,
                                 default = nil)
  if valid_600304 != nil:
    section.add "IndexFieldName", valid_600304
  var valid_600305 = query.getOrDefault("Action")
  valid_600305 = validateParameter(valid_600305, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_600305 != nil:
    section.add "Action", valid_600305
  var valid_600306 = query.getOrDefault("DomainName")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "DomainName", valid_600306
  var valid_600307 = query.getOrDefault("Version")
  valid_600307 = validateParameter(valid_600307, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600307 != nil:
    section.add "Version", valid_600307
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
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600315: Call_GetDeleteIndexField_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600315.validator(path, query, header, formData, body)
  let scheme = call_600315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600315.url(scheme.get, call_600315.host, call_600315.base,
                         call_600315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600315, url, valid)

proc call*(call_600316: Call_GetDeleteIndexField_600301; IndexFieldName: string;
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
  var query_600317 = newJObject()
  add(query_600317, "IndexFieldName", newJString(IndexFieldName))
  add(query_600317, "Action", newJString(Action))
  add(query_600317, "DomainName", newJString(DomainName))
  add(query_600317, "Version", newJString(Version))
  result = call_600316.call(nil, query_600317, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_600301(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_600302, base: "/",
    url: url_GetDeleteIndexField_600303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_600353 = ref object of OpenApiRestCall_599368
proc url_PostDeleteSuggester_600355(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteSuggester_600354(path: JsonNode; query: JsonNode;
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
  var valid_600356 = query.getOrDefault("Action")
  valid_600356 = validateParameter(valid_600356, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_600356 != nil:
    section.add "Action", valid_600356
  var valid_600357 = query.getOrDefault("Version")
  valid_600357 = validateParameter(valid_600357, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600357 != nil:
    section.add "Version", valid_600357
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
  var valid_600358 = header.getOrDefault("X-Amz-Date")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Date", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Security-Token")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Security-Token", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Content-Sha256", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Algorithm")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Algorithm", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Signature")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Signature", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-SignedHeaders", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-Credential")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Credential", valid_600364
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600365 = formData.getOrDefault("DomainName")
  valid_600365 = validateParameter(valid_600365, JString, required = true,
                                 default = nil)
  if valid_600365 != nil:
    section.add "DomainName", valid_600365
  var valid_600366 = formData.getOrDefault("SuggesterName")
  valid_600366 = validateParameter(valid_600366, JString, required = true,
                                 default = nil)
  if valid_600366 != nil:
    section.add "SuggesterName", valid_600366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600367: Call_PostDeleteSuggester_600353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600367.validator(path, query, header, formData, body)
  let scheme = call_600367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600367.url(scheme.get, call_600367.host, call_600367.base,
                         call_600367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600367, url, valid)

proc call*(call_600368: Call_PostDeleteSuggester_600353; DomainName: string;
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
  var query_600369 = newJObject()
  var formData_600370 = newJObject()
  add(formData_600370, "DomainName", newJString(DomainName))
  add(query_600369, "Action", newJString(Action))
  add(formData_600370, "SuggesterName", newJString(SuggesterName))
  add(query_600369, "Version", newJString(Version))
  result = call_600368.call(nil, query_600369, nil, formData_600370, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_600353(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_600354, base: "/",
    url: url_PostDeleteSuggester_600355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_600336 = ref object of OpenApiRestCall_599368
proc url_GetDeleteSuggester_600338(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteSuggester_600337(path: JsonNode; query: JsonNode;
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
  var valid_600339 = query.getOrDefault("Action")
  valid_600339 = validateParameter(valid_600339, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_600339 != nil:
    section.add "Action", valid_600339
  var valid_600340 = query.getOrDefault("SuggesterName")
  valid_600340 = validateParameter(valid_600340, JString, required = true,
                                 default = nil)
  if valid_600340 != nil:
    section.add "SuggesterName", valid_600340
  var valid_600341 = query.getOrDefault("DomainName")
  valid_600341 = validateParameter(valid_600341, JString, required = true,
                                 default = nil)
  if valid_600341 != nil:
    section.add "DomainName", valid_600341
  var valid_600342 = query.getOrDefault("Version")
  valid_600342 = validateParameter(valid_600342, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600342 != nil:
    section.add "Version", valid_600342
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
  var valid_600343 = header.getOrDefault("X-Amz-Date")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Date", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Security-Token")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Security-Token", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Content-Sha256", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Algorithm")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Algorithm", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Signature")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Signature", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-SignedHeaders", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Credential")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Credential", valid_600349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600350: Call_GetDeleteSuggester_600336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600350.validator(path, query, header, formData, body)
  let scheme = call_600350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600350.url(scheme.get, call_600350.host, call_600350.base,
                         call_600350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600350, url, valid)

proc call*(call_600351: Call_GetDeleteSuggester_600336; SuggesterName: string;
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
  var query_600352 = newJObject()
  add(query_600352, "Action", newJString(Action))
  add(query_600352, "SuggesterName", newJString(SuggesterName))
  add(query_600352, "DomainName", newJString(DomainName))
  add(query_600352, "Version", newJString(Version))
  result = call_600351.call(nil, query_600352, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_600336(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_600337, base: "/",
    url: url_GetDeleteSuggester_600338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_600389 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAnalysisSchemes_600391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnalysisSchemes_600390(path: JsonNode; query: JsonNode;
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
  var valid_600392 = query.getOrDefault("Action")
  valid_600392 = validateParameter(valid_600392, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_600392 != nil:
    section.add "Action", valid_600392
  var valid_600393 = query.getOrDefault("Version")
  valid_600393 = validateParameter(valid_600393, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600393 != nil:
    section.add "Version", valid_600393
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
  var valid_600394 = header.getOrDefault("X-Amz-Date")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Date", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Security-Token")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Security-Token", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Content-Sha256", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Algorithm")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Algorithm", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Signature")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Signature", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-SignedHeaders", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Credential")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Credential", valid_600400
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
  var valid_600401 = formData.getOrDefault("DomainName")
  valid_600401 = validateParameter(valid_600401, JString, required = true,
                                 default = nil)
  if valid_600401 != nil:
    section.add "DomainName", valid_600401
  var valid_600402 = formData.getOrDefault("Deployed")
  valid_600402 = validateParameter(valid_600402, JBool, required = false, default = nil)
  if valid_600402 != nil:
    section.add "Deployed", valid_600402
  var valid_600403 = formData.getOrDefault("AnalysisSchemeNames")
  valid_600403 = validateParameter(valid_600403, JArray, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "AnalysisSchemeNames", valid_600403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600404: Call_PostDescribeAnalysisSchemes_600389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600404.validator(path, query, header, formData, body)
  let scheme = call_600404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600404.url(scheme.get, call_600404.host, call_600404.base,
                         call_600404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600404, url, valid)

proc call*(call_600405: Call_PostDescribeAnalysisSchemes_600389;
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
  var query_600406 = newJObject()
  var formData_600407 = newJObject()
  add(formData_600407, "DomainName", newJString(DomainName))
  add(formData_600407, "Deployed", newJBool(Deployed))
  add(query_600406, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_600407.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_600406, "Version", newJString(Version))
  result = call_600405.call(nil, query_600406, nil, formData_600407, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_600389(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_600390, base: "/",
    url: url_PostDescribeAnalysisSchemes_600391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_600371 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAnalysisSchemes_600373(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnalysisSchemes_600372(path: JsonNode; query: JsonNode;
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
  var valid_600374 = query.getOrDefault("Deployed")
  valid_600374 = validateParameter(valid_600374, JBool, required = false, default = nil)
  if valid_600374 != nil:
    section.add "Deployed", valid_600374
  var valid_600375 = query.getOrDefault("AnalysisSchemeNames")
  valid_600375 = validateParameter(valid_600375, JArray, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "AnalysisSchemeNames", valid_600375
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600376 = query.getOrDefault("Action")
  valid_600376 = validateParameter(valid_600376, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_600376 != nil:
    section.add "Action", valid_600376
  var valid_600377 = query.getOrDefault("DomainName")
  valid_600377 = validateParameter(valid_600377, JString, required = true,
                                 default = nil)
  if valid_600377 != nil:
    section.add "DomainName", valid_600377
  var valid_600378 = query.getOrDefault("Version")
  valid_600378 = validateParameter(valid_600378, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600378 != nil:
    section.add "Version", valid_600378
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
  var valid_600379 = header.getOrDefault("X-Amz-Date")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Date", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Security-Token")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Security-Token", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Content-Sha256", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Algorithm")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Algorithm", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Signature")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Signature", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-SignedHeaders", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Credential")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Credential", valid_600385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600386: Call_GetDescribeAnalysisSchemes_600371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600386.validator(path, query, header, formData, body)
  let scheme = call_600386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600386.url(scheme.get, call_600386.host, call_600386.base,
                         call_600386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600386, url, valid)

proc call*(call_600387: Call_GetDescribeAnalysisSchemes_600371; DomainName: string;
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
  var query_600388 = newJObject()
  add(query_600388, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_600388.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_600388, "Action", newJString(Action))
  add(query_600388, "DomainName", newJString(DomainName))
  add(query_600388, "Version", newJString(Version))
  result = call_600387.call(nil, query_600388, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_600371(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_600372, base: "/",
    url: url_GetDescribeAnalysisSchemes_600373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_600425 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAvailabilityOptions_600427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_600426(path: JsonNode;
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
  var valid_600428 = query.getOrDefault("Action")
  valid_600428 = validateParameter(valid_600428, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_600428 != nil:
    section.add "Action", valid_600428
  var valid_600429 = query.getOrDefault("Version")
  valid_600429 = validateParameter(valid_600429, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600429 != nil:
    section.add "Version", valid_600429
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
  var valid_600430 = header.getOrDefault("X-Amz-Date")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Date", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Security-Token")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Security-Token", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Content-Sha256", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Algorithm")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Algorithm", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Signature")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Signature", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-SignedHeaders", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Credential")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Credential", valid_600436
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600437 = formData.getOrDefault("DomainName")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = nil)
  if valid_600437 != nil:
    section.add "DomainName", valid_600437
  var valid_600438 = formData.getOrDefault("Deployed")
  valid_600438 = validateParameter(valid_600438, JBool, required = false, default = nil)
  if valid_600438 != nil:
    section.add "Deployed", valid_600438
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600439: Call_PostDescribeAvailabilityOptions_600425;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600439.validator(path, query, header, formData, body)
  let scheme = call_600439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600439.url(scheme.get, call_600439.host, call_600439.base,
                         call_600439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600439, url, valid)

proc call*(call_600440: Call_PostDescribeAvailabilityOptions_600425;
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
  var query_600441 = newJObject()
  var formData_600442 = newJObject()
  add(formData_600442, "DomainName", newJString(DomainName))
  add(formData_600442, "Deployed", newJBool(Deployed))
  add(query_600441, "Action", newJString(Action))
  add(query_600441, "Version", newJString(Version))
  result = call_600440.call(nil, query_600441, nil, formData_600442, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_600425(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_600426, base: "/",
    url: url_PostDescribeAvailabilityOptions_600427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_600408 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAvailabilityOptions_600410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_600409(path: JsonNode;
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
  var valid_600411 = query.getOrDefault("Deployed")
  valid_600411 = validateParameter(valid_600411, JBool, required = false, default = nil)
  if valid_600411 != nil:
    section.add "Deployed", valid_600411
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600412 = query.getOrDefault("Action")
  valid_600412 = validateParameter(valid_600412, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_600412 != nil:
    section.add "Action", valid_600412
  var valid_600413 = query.getOrDefault("DomainName")
  valid_600413 = validateParameter(valid_600413, JString, required = true,
                                 default = nil)
  if valid_600413 != nil:
    section.add "DomainName", valid_600413
  var valid_600414 = query.getOrDefault("Version")
  valid_600414 = validateParameter(valid_600414, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600414 != nil:
    section.add "Version", valid_600414
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
  var valid_600415 = header.getOrDefault("X-Amz-Date")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Date", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Security-Token")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Security-Token", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Content-Sha256", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Algorithm")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Algorithm", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Signature")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Signature", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-SignedHeaders", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Credential")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Credential", valid_600421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600422: Call_GetDescribeAvailabilityOptions_600408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600422.validator(path, query, header, formData, body)
  let scheme = call_600422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600422.url(scheme.get, call_600422.host, call_600422.base,
                         call_600422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600422, url, valid)

proc call*(call_600423: Call_GetDescribeAvailabilityOptions_600408;
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
  var query_600424 = newJObject()
  add(query_600424, "Deployed", newJBool(Deployed))
  add(query_600424, "Action", newJString(Action))
  add(query_600424, "DomainName", newJString(DomainName))
  add(query_600424, "Version", newJString(Version))
  result = call_600423.call(nil, query_600424, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_600408(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_600409, base: "/",
    url: url_GetDescribeAvailabilityOptions_600410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_600460 = ref object of OpenApiRestCall_599368
proc url_PostDescribeDomainEndpointOptions_600462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomainEndpointOptions_600461(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
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
  var valid_600463 = query.getOrDefault("Action")
  valid_600463 = validateParameter(valid_600463, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_600463 != nil:
    section.add "Action", valid_600463
  var valid_600464 = query.getOrDefault("Version")
  valid_600464 = validateParameter(valid_600464, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600464 != nil:
    section.add "Version", valid_600464
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
  var valid_600465 = header.getOrDefault("X-Amz-Date")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Date", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Security-Token")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Security-Token", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Content-Sha256", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Algorithm")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Algorithm", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Signature")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Signature", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-SignedHeaders", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Credential")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Credential", valid_600471
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600472 = formData.getOrDefault("DomainName")
  valid_600472 = validateParameter(valid_600472, JString, required = true,
                                 default = nil)
  if valid_600472 != nil:
    section.add "DomainName", valid_600472
  var valid_600473 = formData.getOrDefault("Deployed")
  valid_600473 = validateParameter(valid_600473, JBool, required = false, default = nil)
  if valid_600473 != nil:
    section.add "Deployed", valid_600473
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600474: Call_PostDescribeDomainEndpointOptions_600460;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600474.validator(path, query, header, formData, body)
  let scheme = call_600474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600474.url(scheme.get, call_600474.host, call_600474.base,
                         call_600474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600474, url, valid)

proc call*(call_600475: Call_PostDescribeDomainEndpointOptions_600460;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600476 = newJObject()
  var formData_600477 = newJObject()
  add(formData_600477, "DomainName", newJString(DomainName))
  add(formData_600477, "Deployed", newJBool(Deployed))
  add(query_600476, "Action", newJString(Action))
  add(query_600476, "Version", newJString(Version))
  result = call_600475.call(nil, query_600476, nil, formData_600477, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_600460(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_600461, base: "/",
    url: url_PostDescribeDomainEndpointOptions_600462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_600443 = ref object of OpenApiRestCall_599368
proc url_GetDescribeDomainEndpointOptions_600445(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomainEndpointOptions_600444(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_600446 = query.getOrDefault("Deployed")
  valid_600446 = validateParameter(valid_600446, JBool, required = false, default = nil)
  if valid_600446 != nil:
    section.add "Deployed", valid_600446
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600447 = query.getOrDefault("Action")
  valid_600447 = validateParameter(valid_600447, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_600447 != nil:
    section.add "Action", valid_600447
  var valid_600448 = query.getOrDefault("DomainName")
  valid_600448 = validateParameter(valid_600448, JString, required = true,
                                 default = nil)
  if valid_600448 != nil:
    section.add "DomainName", valid_600448
  var valid_600449 = query.getOrDefault("Version")
  valid_600449 = validateParameter(valid_600449, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600449 != nil:
    section.add "Version", valid_600449
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
  var valid_600450 = header.getOrDefault("X-Amz-Date")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Date", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Security-Token")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Security-Token", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Content-Sha256", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Algorithm")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Algorithm", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Signature")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Signature", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-SignedHeaders", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Credential")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Credential", valid_600456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600457: Call_GetDescribeDomainEndpointOptions_600443;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600457.validator(path, query, header, formData, body)
  let scheme = call_600457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600457.url(scheme.get, call_600457.host, call_600457.base,
                         call_600457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600457, url, valid)

proc call*(call_600458: Call_GetDescribeDomainEndpointOptions_600443;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600459 = newJObject()
  add(query_600459, "Deployed", newJBool(Deployed))
  add(query_600459, "Action", newJString(Action))
  add(query_600459, "DomainName", newJString(DomainName))
  add(query_600459, "Version", newJString(Version))
  result = call_600458.call(nil, query_600459, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_600443(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_600444, base: "/",
    url: url_GetDescribeDomainEndpointOptions_600445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_600494 = ref object of OpenApiRestCall_599368
proc url_PostDescribeDomains_600496(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_600495(path: JsonNode; query: JsonNode;
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
  var valid_600497 = query.getOrDefault("Action")
  valid_600497 = validateParameter(valid_600497, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_600497 != nil:
    section.add "Action", valid_600497
  var valid_600498 = query.getOrDefault("Version")
  valid_600498 = validateParameter(valid_600498, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600498 != nil:
    section.add "Version", valid_600498
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
  var valid_600499 = header.getOrDefault("X-Amz-Date")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Date", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Security-Token")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Security-Token", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Content-Sha256", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Algorithm")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Algorithm", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Signature")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Signature", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-SignedHeaders", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Credential")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Credential", valid_600505
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_600506 = formData.getOrDefault("DomainNames")
  valid_600506 = validateParameter(valid_600506, JArray, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "DomainNames", valid_600506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600507: Call_PostDescribeDomains_600494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600507.validator(path, query, header, formData, body)
  let scheme = call_600507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600507.url(scheme.get, call_600507.host, call_600507.base,
                         call_600507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600507, url, valid)

proc call*(call_600508: Call_PostDescribeDomains_600494;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600509 = newJObject()
  var formData_600510 = newJObject()
  if DomainNames != nil:
    formData_600510.add "DomainNames", DomainNames
  add(query_600509, "Action", newJString(Action))
  add(query_600509, "Version", newJString(Version))
  result = call_600508.call(nil, query_600509, nil, formData_600510, nil)

var postDescribeDomains* = Call_PostDescribeDomains_600494(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_600495, base: "/",
    url: url_PostDescribeDomains_600496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_600478 = ref object of OpenApiRestCall_599368
proc url_GetDescribeDomains_600480(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_600479(path: JsonNode; query: JsonNode;
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
  var valid_600481 = query.getOrDefault("DomainNames")
  valid_600481 = validateParameter(valid_600481, JArray, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "DomainNames", valid_600481
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600482 = query.getOrDefault("Action")
  valid_600482 = validateParameter(valid_600482, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_600482 != nil:
    section.add "Action", valid_600482
  var valid_600483 = query.getOrDefault("Version")
  valid_600483 = validateParameter(valid_600483, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600483 != nil:
    section.add "Version", valid_600483
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
  var valid_600484 = header.getOrDefault("X-Amz-Date")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Date", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Security-Token")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Security-Token", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Content-Sha256", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Algorithm")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Algorithm", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Signature")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Signature", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-SignedHeaders", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Credential")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Credential", valid_600490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600491: Call_GetDescribeDomains_600478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600491.validator(path, query, header, formData, body)
  let scheme = call_600491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600491.url(scheme.get, call_600491.host, call_600491.base,
                         call_600491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600491, url, valid)

proc call*(call_600492: Call_GetDescribeDomains_600478;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600493 = newJObject()
  if DomainNames != nil:
    query_600493.add "DomainNames", DomainNames
  add(query_600493, "Action", newJString(Action))
  add(query_600493, "Version", newJString(Version))
  result = call_600492.call(nil, query_600493, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_600478(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_600479, base: "/",
    url: url_GetDescribeDomains_600480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_600529 = ref object of OpenApiRestCall_599368
proc url_PostDescribeExpressions_600531(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeExpressions_600530(path: JsonNode; query: JsonNode;
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
  var valid_600532 = query.getOrDefault("Action")
  valid_600532 = validateParameter(valid_600532, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_600532 != nil:
    section.add "Action", valid_600532
  var valid_600533 = query.getOrDefault("Version")
  valid_600533 = validateParameter(valid_600533, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600533 != nil:
    section.add "Version", valid_600533
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
  var valid_600534 = header.getOrDefault("X-Amz-Date")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Date", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Security-Token")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Security-Token", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Content-Sha256", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Algorithm")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Algorithm", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Signature")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Signature", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-SignedHeaders", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Credential")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Credential", valid_600540
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
  var valid_600541 = formData.getOrDefault("DomainName")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = nil)
  if valid_600541 != nil:
    section.add "DomainName", valid_600541
  var valid_600542 = formData.getOrDefault("Deployed")
  valid_600542 = validateParameter(valid_600542, JBool, required = false, default = nil)
  if valid_600542 != nil:
    section.add "Deployed", valid_600542
  var valid_600543 = formData.getOrDefault("ExpressionNames")
  valid_600543 = validateParameter(valid_600543, JArray, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "ExpressionNames", valid_600543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600544: Call_PostDescribeExpressions_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600544.validator(path, query, header, formData, body)
  let scheme = call_600544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600544.url(scheme.get, call_600544.host, call_600544.base,
                         call_600544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600544, url, valid)

proc call*(call_600545: Call_PostDescribeExpressions_600529; DomainName: string;
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
  var query_600546 = newJObject()
  var formData_600547 = newJObject()
  add(formData_600547, "DomainName", newJString(DomainName))
  add(formData_600547, "Deployed", newJBool(Deployed))
  add(query_600546, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_600547.add "ExpressionNames", ExpressionNames
  add(query_600546, "Version", newJString(Version))
  result = call_600545.call(nil, query_600546, nil, formData_600547, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_600529(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_600530, base: "/",
    url: url_PostDescribeExpressions_600531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_600511 = ref object of OpenApiRestCall_599368
proc url_GetDescribeExpressions_600513(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeExpressions_600512(path: JsonNode; query: JsonNode;
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
  var valid_600514 = query.getOrDefault("Deployed")
  valid_600514 = validateParameter(valid_600514, JBool, required = false, default = nil)
  if valid_600514 != nil:
    section.add "Deployed", valid_600514
  var valid_600515 = query.getOrDefault("ExpressionNames")
  valid_600515 = validateParameter(valid_600515, JArray, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "ExpressionNames", valid_600515
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600516 = query.getOrDefault("Action")
  valid_600516 = validateParameter(valid_600516, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_600516 != nil:
    section.add "Action", valid_600516
  var valid_600517 = query.getOrDefault("DomainName")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "DomainName", valid_600517
  var valid_600518 = query.getOrDefault("Version")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600518 != nil:
    section.add "Version", valid_600518
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
  var valid_600519 = header.getOrDefault("X-Amz-Date")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Date", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Security-Token")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Security-Token", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Content-Sha256", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Algorithm")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Algorithm", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Signature")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Signature", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-SignedHeaders", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Credential")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Credential", valid_600525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_GetDescribeExpressions_600511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_GetDescribeExpressions_600511; DomainName: string;
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
  var query_600528 = newJObject()
  add(query_600528, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_600528.add "ExpressionNames", ExpressionNames
  add(query_600528, "Action", newJString(Action))
  add(query_600528, "DomainName", newJString(DomainName))
  add(query_600528, "Version", newJString(Version))
  result = call_600527.call(nil, query_600528, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_600511(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_600512, base: "/",
    url: url_GetDescribeExpressions_600513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_600566 = ref object of OpenApiRestCall_599368
proc url_PostDescribeIndexFields_600568(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_600567(path: JsonNode; query: JsonNode;
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
  var valid_600569 = query.getOrDefault("Action")
  valid_600569 = validateParameter(valid_600569, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_600569 != nil:
    section.add "Action", valid_600569
  var valid_600570 = query.getOrDefault("Version")
  valid_600570 = validateParameter(valid_600570, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600570 != nil:
    section.add "Version", valid_600570
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
  var valid_600571 = header.getOrDefault("X-Amz-Date")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Date", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Security-Token")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Security-Token", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Content-Sha256", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Algorithm")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Algorithm", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Signature")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Signature", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-SignedHeaders", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Credential")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Credential", valid_600577
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
  var valid_600578 = formData.getOrDefault("DomainName")
  valid_600578 = validateParameter(valid_600578, JString, required = true,
                                 default = nil)
  if valid_600578 != nil:
    section.add "DomainName", valid_600578
  var valid_600579 = formData.getOrDefault("Deployed")
  valid_600579 = validateParameter(valid_600579, JBool, required = false, default = nil)
  if valid_600579 != nil:
    section.add "Deployed", valid_600579
  var valid_600580 = formData.getOrDefault("FieldNames")
  valid_600580 = validateParameter(valid_600580, JArray, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "FieldNames", valid_600580
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600581: Call_PostDescribeIndexFields_600566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600581.validator(path, query, header, formData, body)
  let scheme = call_600581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600581.url(scheme.get, call_600581.host, call_600581.base,
                         call_600581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600581, url, valid)

proc call*(call_600582: Call_PostDescribeIndexFields_600566; DomainName: string;
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
  var query_600583 = newJObject()
  var formData_600584 = newJObject()
  add(formData_600584, "DomainName", newJString(DomainName))
  add(formData_600584, "Deployed", newJBool(Deployed))
  add(query_600583, "Action", newJString(Action))
  if FieldNames != nil:
    formData_600584.add "FieldNames", FieldNames
  add(query_600583, "Version", newJString(Version))
  result = call_600582.call(nil, query_600583, nil, formData_600584, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_600566(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_600567, base: "/",
    url: url_PostDescribeIndexFields_600568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_600548 = ref object of OpenApiRestCall_599368
proc url_GetDescribeIndexFields_600550(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_600549(path: JsonNode; query: JsonNode;
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
  var valid_600551 = query.getOrDefault("Deployed")
  valid_600551 = validateParameter(valid_600551, JBool, required = false, default = nil)
  if valid_600551 != nil:
    section.add "Deployed", valid_600551
  var valid_600552 = query.getOrDefault("FieldNames")
  valid_600552 = validateParameter(valid_600552, JArray, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "FieldNames", valid_600552
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600553 = query.getOrDefault("Action")
  valid_600553 = validateParameter(valid_600553, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_600553 != nil:
    section.add "Action", valid_600553
  var valid_600554 = query.getOrDefault("DomainName")
  valid_600554 = validateParameter(valid_600554, JString, required = true,
                                 default = nil)
  if valid_600554 != nil:
    section.add "DomainName", valid_600554
  var valid_600555 = query.getOrDefault("Version")
  valid_600555 = validateParameter(valid_600555, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600555 != nil:
    section.add "Version", valid_600555
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
  var valid_600556 = header.getOrDefault("X-Amz-Date")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Date", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Security-Token")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Security-Token", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Content-Sha256", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Algorithm")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Algorithm", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Signature")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Signature", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-SignedHeaders", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Credential")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Credential", valid_600562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600563: Call_GetDescribeIndexFields_600548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600563.validator(path, query, header, formData, body)
  let scheme = call_600563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600563.url(scheme.get, call_600563.host, call_600563.base,
                         call_600563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600563, url, valid)

proc call*(call_600564: Call_GetDescribeIndexFields_600548; DomainName: string;
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
  var query_600565 = newJObject()
  add(query_600565, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_600565.add "FieldNames", FieldNames
  add(query_600565, "Action", newJString(Action))
  add(query_600565, "DomainName", newJString(DomainName))
  add(query_600565, "Version", newJString(Version))
  result = call_600564.call(nil, query_600565, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_600548(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_600549, base: "/",
    url: url_GetDescribeIndexFields_600550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_600601 = ref object of OpenApiRestCall_599368
proc url_PostDescribeScalingParameters_600603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeScalingParameters_600602(path: JsonNode; query: JsonNode;
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
  var valid_600604 = query.getOrDefault("Action")
  valid_600604 = validateParameter(valid_600604, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_600604 != nil:
    section.add "Action", valid_600604
  var valid_600605 = query.getOrDefault("Version")
  valid_600605 = validateParameter(valid_600605, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600605 != nil:
    section.add "Version", valid_600605
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
  var valid_600606 = header.getOrDefault("X-Amz-Date")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Date", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Security-Token")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Security-Token", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Content-Sha256", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Algorithm")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Algorithm", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Signature")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Signature", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-SignedHeaders", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Credential")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Credential", valid_600612
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600613 = formData.getOrDefault("DomainName")
  valid_600613 = validateParameter(valid_600613, JString, required = true,
                                 default = nil)
  if valid_600613 != nil:
    section.add "DomainName", valid_600613
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600614: Call_PostDescribeScalingParameters_600601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600614.validator(path, query, header, formData, body)
  let scheme = call_600614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600614.url(scheme.get, call_600614.host, call_600614.base,
                         call_600614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600614, url, valid)

proc call*(call_600615: Call_PostDescribeScalingParameters_600601;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600616 = newJObject()
  var formData_600617 = newJObject()
  add(formData_600617, "DomainName", newJString(DomainName))
  add(query_600616, "Action", newJString(Action))
  add(query_600616, "Version", newJString(Version))
  result = call_600615.call(nil, query_600616, nil, formData_600617, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_600601(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_600602, base: "/",
    url: url_PostDescribeScalingParameters_600603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_600585 = ref object of OpenApiRestCall_599368
proc url_GetDescribeScalingParameters_600587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeScalingParameters_600586(path: JsonNode; query: JsonNode;
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
  var valid_600588 = query.getOrDefault("Action")
  valid_600588 = validateParameter(valid_600588, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_600588 != nil:
    section.add "Action", valid_600588
  var valid_600589 = query.getOrDefault("DomainName")
  valid_600589 = validateParameter(valid_600589, JString, required = true,
                                 default = nil)
  if valid_600589 != nil:
    section.add "DomainName", valid_600589
  var valid_600590 = query.getOrDefault("Version")
  valid_600590 = validateParameter(valid_600590, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600590 != nil:
    section.add "Version", valid_600590
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
  var valid_600591 = header.getOrDefault("X-Amz-Date")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Date", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Security-Token")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Security-Token", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Content-Sha256", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Algorithm")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Algorithm", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Signature")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Signature", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-SignedHeaders", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Credential")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Credential", valid_600597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600598: Call_GetDescribeScalingParameters_600585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600598.validator(path, query, header, formData, body)
  let scheme = call_600598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600598.url(scheme.get, call_600598.host, call_600598.base,
                         call_600598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600598, url, valid)

proc call*(call_600599: Call_GetDescribeScalingParameters_600585;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600600 = newJObject()
  add(query_600600, "Action", newJString(Action))
  add(query_600600, "DomainName", newJString(DomainName))
  add(query_600600, "Version", newJString(Version))
  result = call_600599.call(nil, query_600600, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_600585(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_600586, base: "/",
    url: url_GetDescribeScalingParameters_600587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_600635 = ref object of OpenApiRestCall_599368
proc url_PostDescribeServiceAccessPolicies_600637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_600636(path: JsonNode;
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
  var valid_600638 = query.getOrDefault("Action")
  valid_600638 = validateParameter(valid_600638, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_600638 != nil:
    section.add "Action", valid_600638
  var valid_600639 = query.getOrDefault("Version")
  valid_600639 = validateParameter(valid_600639, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600639 != nil:
    section.add "Version", valid_600639
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
  var valid_600640 = header.getOrDefault("X-Amz-Date")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Date", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Security-Token")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Security-Token", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Content-Sha256", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Algorithm")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Algorithm", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Signature")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Signature", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-SignedHeaders", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-Credential")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-Credential", valid_600646
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600647 = formData.getOrDefault("DomainName")
  valid_600647 = validateParameter(valid_600647, JString, required = true,
                                 default = nil)
  if valid_600647 != nil:
    section.add "DomainName", valid_600647
  var valid_600648 = formData.getOrDefault("Deployed")
  valid_600648 = validateParameter(valid_600648, JBool, required = false, default = nil)
  if valid_600648 != nil:
    section.add "Deployed", valid_600648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600649: Call_PostDescribeServiceAccessPolicies_600635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600649.validator(path, query, header, formData, body)
  let scheme = call_600649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600649.url(scheme.get, call_600649.host, call_600649.base,
                         call_600649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600649, url, valid)

proc call*(call_600650: Call_PostDescribeServiceAccessPolicies_600635;
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
  var query_600651 = newJObject()
  var formData_600652 = newJObject()
  add(formData_600652, "DomainName", newJString(DomainName))
  add(formData_600652, "Deployed", newJBool(Deployed))
  add(query_600651, "Action", newJString(Action))
  add(query_600651, "Version", newJString(Version))
  result = call_600650.call(nil, query_600651, nil, formData_600652, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_600635(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_600636, base: "/",
    url: url_PostDescribeServiceAccessPolicies_600637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_600618 = ref object of OpenApiRestCall_599368
proc url_GetDescribeServiceAccessPolicies_600620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_600619(path: JsonNode;
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
  var valid_600621 = query.getOrDefault("Deployed")
  valid_600621 = validateParameter(valid_600621, JBool, required = false, default = nil)
  if valid_600621 != nil:
    section.add "Deployed", valid_600621
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600622 = query.getOrDefault("Action")
  valid_600622 = validateParameter(valid_600622, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_600622 != nil:
    section.add "Action", valid_600622
  var valid_600623 = query.getOrDefault("DomainName")
  valid_600623 = validateParameter(valid_600623, JString, required = true,
                                 default = nil)
  if valid_600623 != nil:
    section.add "DomainName", valid_600623
  var valid_600624 = query.getOrDefault("Version")
  valid_600624 = validateParameter(valid_600624, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600624 != nil:
    section.add "Version", valid_600624
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
  var valid_600625 = header.getOrDefault("X-Amz-Date")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Date", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Security-Token")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Security-Token", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Content-Sha256", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Algorithm")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Algorithm", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Signature")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Signature", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-SignedHeaders", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-Credential")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Credential", valid_600631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600632: Call_GetDescribeServiceAccessPolicies_600618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600632.validator(path, query, header, formData, body)
  let scheme = call_600632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600632.url(scheme.get, call_600632.host, call_600632.base,
                         call_600632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600632, url, valid)

proc call*(call_600633: Call_GetDescribeServiceAccessPolicies_600618;
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
  var query_600634 = newJObject()
  add(query_600634, "Deployed", newJBool(Deployed))
  add(query_600634, "Action", newJString(Action))
  add(query_600634, "DomainName", newJString(DomainName))
  add(query_600634, "Version", newJString(Version))
  result = call_600633.call(nil, query_600634, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_600618(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_600619, base: "/",
    url: url_GetDescribeServiceAccessPolicies_600620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_600671 = ref object of OpenApiRestCall_599368
proc url_PostDescribeSuggesters_600673(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSuggesters_600672(path: JsonNode; query: JsonNode;
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
  var valid_600674 = query.getOrDefault("Action")
  valid_600674 = validateParameter(valid_600674, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_600674 != nil:
    section.add "Action", valid_600674
  var valid_600675 = query.getOrDefault("Version")
  valid_600675 = validateParameter(valid_600675, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600675 != nil:
    section.add "Version", valid_600675
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
  var valid_600676 = header.getOrDefault("X-Amz-Date")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Date", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Security-Token")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Security-Token", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Content-Sha256", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Algorithm")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Algorithm", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Signature")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Signature", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-SignedHeaders", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Credential")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Credential", valid_600682
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
  var valid_600683 = formData.getOrDefault("DomainName")
  valid_600683 = validateParameter(valid_600683, JString, required = true,
                                 default = nil)
  if valid_600683 != nil:
    section.add "DomainName", valid_600683
  var valid_600684 = formData.getOrDefault("Deployed")
  valid_600684 = validateParameter(valid_600684, JBool, required = false, default = nil)
  if valid_600684 != nil:
    section.add "Deployed", valid_600684
  var valid_600685 = formData.getOrDefault("SuggesterNames")
  valid_600685 = validateParameter(valid_600685, JArray, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "SuggesterNames", valid_600685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600686: Call_PostDescribeSuggesters_600671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600686.validator(path, query, header, formData, body)
  let scheme = call_600686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600686.url(scheme.get, call_600686.host, call_600686.base,
                         call_600686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600686, url, valid)

proc call*(call_600687: Call_PostDescribeSuggesters_600671; DomainName: string;
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
  var query_600688 = newJObject()
  var formData_600689 = newJObject()
  add(formData_600689, "DomainName", newJString(DomainName))
  add(formData_600689, "Deployed", newJBool(Deployed))
  add(query_600688, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_600689.add "SuggesterNames", SuggesterNames
  add(query_600688, "Version", newJString(Version))
  result = call_600687.call(nil, query_600688, nil, formData_600689, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_600671(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_600672, base: "/",
    url: url_PostDescribeSuggesters_600673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_600653 = ref object of OpenApiRestCall_599368
proc url_GetDescribeSuggesters_600655(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSuggesters_600654(path: JsonNode; query: JsonNode;
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
  var valid_600656 = query.getOrDefault("Deployed")
  valid_600656 = validateParameter(valid_600656, JBool, required = false, default = nil)
  if valid_600656 != nil:
    section.add "Deployed", valid_600656
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600657 = query.getOrDefault("Action")
  valid_600657 = validateParameter(valid_600657, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_600657 != nil:
    section.add "Action", valid_600657
  var valid_600658 = query.getOrDefault("DomainName")
  valid_600658 = validateParameter(valid_600658, JString, required = true,
                                 default = nil)
  if valid_600658 != nil:
    section.add "DomainName", valid_600658
  var valid_600659 = query.getOrDefault("Version")
  valid_600659 = validateParameter(valid_600659, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600659 != nil:
    section.add "Version", valid_600659
  var valid_600660 = query.getOrDefault("SuggesterNames")
  valid_600660 = validateParameter(valid_600660, JArray, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "SuggesterNames", valid_600660
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
  var valid_600661 = header.getOrDefault("X-Amz-Date")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Date", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Security-Token")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Security-Token", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Content-Sha256", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Algorithm")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Algorithm", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Signature")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Signature", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-SignedHeaders", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Credential")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Credential", valid_600667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600668: Call_GetDescribeSuggesters_600653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600668.validator(path, query, header, formData, body)
  let scheme = call_600668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600668.url(scheme.get, call_600668.host, call_600668.base,
                         call_600668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600668, url, valid)

proc call*(call_600669: Call_GetDescribeSuggesters_600653; DomainName: string;
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
  var query_600670 = newJObject()
  add(query_600670, "Deployed", newJBool(Deployed))
  add(query_600670, "Action", newJString(Action))
  add(query_600670, "DomainName", newJString(DomainName))
  add(query_600670, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_600670.add "SuggesterNames", SuggesterNames
  result = call_600669.call(nil, query_600670, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_600653(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_600654, base: "/",
    url: url_GetDescribeSuggesters_600655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_600706 = ref object of OpenApiRestCall_599368
proc url_PostIndexDocuments_600708(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_600707(path: JsonNode; query: JsonNode;
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
  var valid_600709 = query.getOrDefault("Action")
  valid_600709 = validateParameter(valid_600709, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_600709 != nil:
    section.add "Action", valid_600709
  var valid_600710 = query.getOrDefault("Version")
  valid_600710 = validateParameter(valid_600710, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600710 != nil:
    section.add "Version", valid_600710
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
  var valid_600711 = header.getOrDefault("X-Amz-Date")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Date", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Security-Token")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Security-Token", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Content-Sha256", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-Algorithm")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Algorithm", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Signature")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Signature", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-SignedHeaders", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Credential")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Credential", valid_600717
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600718 = formData.getOrDefault("DomainName")
  valid_600718 = validateParameter(valid_600718, JString, required = true,
                                 default = nil)
  if valid_600718 != nil:
    section.add "DomainName", valid_600718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600719: Call_PostIndexDocuments_600706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_600719.validator(path, query, header, formData, body)
  let scheme = call_600719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600719.url(scheme.get, call_600719.host, call_600719.base,
                         call_600719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600719, url, valid)

proc call*(call_600720: Call_PostIndexDocuments_600706; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600721 = newJObject()
  var formData_600722 = newJObject()
  add(formData_600722, "DomainName", newJString(DomainName))
  add(query_600721, "Action", newJString(Action))
  add(query_600721, "Version", newJString(Version))
  result = call_600720.call(nil, query_600721, nil, formData_600722, nil)

var postIndexDocuments* = Call_PostIndexDocuments_600706(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_600707, base: "/",
    url: url_PostIndexDocuments_600708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_600690 = ref object of OpenApiRestCall_599368
proc url_GetIndexDocuments_600692(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_600691(path: JsonNode; query: JsonNode;
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
  var valid_600693 = query.getOrDefault("Action")
  valid_600693 = validateParameter(valid_600693, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_600693 != nil:
    section.add "Action", valid_600693
  var valid_600694 = query.getOrDefault("DomainName")
  valid_600694 = validateParameter(valid_600694, JString, required = true,
                                 default = nil)
  if valid_600694 != nil:
    section.add "DomainName", valid_600694
  var valid_600695 = query.getOrDefault("Version")
  valid_600695 = validateParameter(valid_600695, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600695 != nil:
    section.add "Version", valid_600695
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
  var valid_600696 = header.getOrDefault("X-Amz-Date")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Date", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Security-Token")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Security-Token", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Content-Sha256", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Algorithm")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Algorithm", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Signature")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Signature", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-SignedHeaders", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Credential")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Credential", valid_600702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600703: Call_GetIndexDocuments_600690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_600703.validator(path, query, header, formData, body)
  let scheme = call_600703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600703.url(scheme.get, call_600703.host, call_600703.base,
                         call_600703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600703, url, valid)

proc call*(call_600704: Call_GetIndexDocuments_600690; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600705 = newJObject()
  add(query_600705, "Action", newJString(Action))
  add(query_600705, "DomainName", newJString(DomainName))
  add(query_600705, "Version", newJString(Version))
  result = call_600704.call(nil, query_600705, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_600690(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_600691,
    base: "/", url: url_GetIndexDocuments_600692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_600738 = ref object of OpenApiRestCall_599368
proc url_PostListDomainNames_600740(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomainNames_600739(path: JsonNode; query: JsonNode;
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
  var valid_600741 = query.getOrDefault("Action")
  valid_600741 = validateParameter(valid_600741, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_600741 != nil:
    section.add "Action", valid_600741
  var valid_600742 = query.getOrDefault("Version")
  valid_600742 = validateParameter(valid_600742, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600742 != nil:
    section.add "Version", valid_600742
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
  var valid_600743 = header.getOrDefault("X-Amz-Date")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Date", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-Security-Token")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-Security-Token", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Content-Sha256", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Algorithm")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Algorithm", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Signature")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Signature", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-SignedHeaders", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Credential")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Credential", valid_600749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600750: Call_PostListDomainNames_600738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_600750.validator(path, query, header, formData, body)
  let scheme = call_600750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600750.url(scheme.get, call_600750.host, call_600750.base,
                         call_600750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600750, url, valid)

proc call*(call_600751: Call_PostListDomainNames_600738;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600752 = newJObject()
  add(query_600752, "Action", newJString(Action))
  add(query_600752, "Version", newJString(Version))
  result = call_600751.call(nil, query_600752, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_600738(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_600739, base: "/",
    url: url_PostListDomainNames_600740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_600723 = ref object of OpenApiRestCall_599368
proc url_GetListDomainNames_600725(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomainNames_600724(path: JsonNode; query: JsonNode;
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
  var valid_600726 = query.getOrDefault("Action")
  valid_600726 = validateParameter(valid_600726, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_600726 != nil:
    section.add "Action", valid_600726
  var valid_600727 = query.getOrDefault("Version")
  valid_600727 = validateParameter(valid_600727, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600727 != nil:
    section.add "Version", valid_600727
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
  var valid_600728 = header.getOrDefault("X-Amz-Date")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Date", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Security-Token")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Security-Token", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Content-Sha256", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Algorithm")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Algorithm", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Signature")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Signature", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-SignedHeaders", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Credential")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Credential", valid_600734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600735: Call_GetListDomainNames_600723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_600735.validator(path, query, header, formData, body)
  let scheme = call_600735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600735.url(scheme.get, call_600735.host, call_600735.base,
                         call_600735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600735, url, valid)

proc call*(call_600736: Call_GetListDomainNames_600723;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600737 = newJObject()
  add(query_600737, "Action", newJString(Action))
  add(query_600737, "Version", newJString(Version))
  result = call_600736.call(nil, query_600737, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_600723(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_600724, base: "/",
    url: url_GetListDomainNames_600725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_600770 = ref object of OpenApiRestCall_599368
proc url_PostUpdateAvailabilityOptions_600772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_600771(path: JsonNode; query: JsonNode;
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
  var valid_600773 = query.getOrDefault("Action")
  valid_600773 = validateParameter(valid_600773, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_600773 != nil:
    section.add "Action", valid_600773
  var valid_600774 = query.getOrDefault("Version")
  valid_600774 = validateParameter(valid_600774, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600774 != nil:
    section.add "Version", valid_600774
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
  var valid_600775 = header.getOrDefault("X-Amz-Date")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Date", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Security-Token")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Security-Token", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Content-Sha256", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Algorithm")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Algorithm", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Signature")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Signature", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-SignedHeaders", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-Credential")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-Credential", valid_600781
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600782 = formData.getOrDefault("DomainName")
  valid_600782 = validateParameter(valid_600782, JString, required = true,
                                 default = nil)
  if valid_600782 != nil:
    section.add "DomainName", valid_600782
  var valid_600783 = formData.getOrDefault("MultiAZ")
  valid_600783 = validateParameter(valid_600783, JBool, required = true, default = nil)
  if valid_600783 != nil:
    section.add "MultiAZ", valid_600783
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600784: Call_PostUpdateAvailabilityOptions_600770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600784.validator(path, query, header, formData, body)
  let scheme = call_600784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600784.url(scheme.get, call_600784.host, call_600784.base,
                         call_600784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600784, url, valid)

proc call*(call_600785: Call_PostUpdateAvailabilityOptions_600770;
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
  var query_600786 = newJObject()
  var formData_600787 = newJObject()
  add(formData_600787, "DomainName", newJString(DomainName))
  add(formData_600787, "MultiAZ", newJBool(MultiAZ))
  add(query_600786, "Action", newJString(Action))
  add(query_600786, "Version", newJString(Version))
  result = call_600785.call(nil, query_600786, nil, formData_600787, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_600770(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_600771, base: "/",
    url: url_PostUpdateAvailabilityOptions_600772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_600753 = ref object of OpenApiRestCall_599368
proc url_GetUpdateAvailabilityOptions_600755(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_600754(path: JsonNode; query: JsonNode;
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
  var valid_600756 = query.getOrDefault("MultiAZ")
  valid_600756 = validateParameter(valid_600756, JBool, required = true, default = nil)
  if valid_600756 != nil:
    section.add "MultiAZ", valid_600756
  var valid_600757 = query.getOrDefault("Action")
  valid_600757 = validateParameter(valid_600757, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_600757 != nil:
    section.add "Action", valid_600757
  var valid_600758 = query.getOrDefault("DomainName")
  valid_600758 = validateParameter(valid_600758, JString, required = true,
                                 default = nil)
  if valid_600758 != nil:
    section.add "DomainName", valid_600758
  var valid_600759 = query.getOrDefault("Version")
  valid_600759 = validateParameter(valid_600759, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600759 != nil:
    section.add "Version", valid_600759
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
  var valid_600760 = header.getOrDefault("X-Amz-Date")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Date", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Security-Token")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Security-Token", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Content-Sha256", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Algorithm")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Algorithm", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Signature")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Signature", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-SignedHeaders", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Credential")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Credential", valid_600766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600767: Call_GetUpdateAvailabilityOptions_600753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600767.validator(path, query, header, formData, body)
  let scheme = call_600767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600767.url(scheme.get, call_600767.host, call_600767.base,
                         call_600767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600767, url, valid)

proc call*(call_600768: Call_GetUpdateAvailabilityOptions_600753; MultiAZ: bool;
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
  var query_600769 = newJObject()
  add(query_600769, "MultiAZ", newJBool(MultiAZ))
  add(query_600769, "Action", newJString(Action))
  add(query_600769, "DomainName", newJString(DomainName))
  add(query_600769, "Version", newJString(Version))
  result = call_600768.call(nil, query_600769, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_600753(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_600754, base: "/",
    url: url_GetUpdateAvailabilityOptions_600755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_600806 = ref object of OpenApiRestCall_599368
proc url_PostUpdateDomainEndpointOptions_600808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDomainEndpointOptions_600807(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
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
  var valid_600809 = query.getOrDefault("Action")
  valid_600809 = validateParameter(valid_600809, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_600809 != nil:
    section.add "Action", valid_600809
  var valid_600810 = query.getOrDefault("Version")
  valid_600810 = validateParameter(valid_600810, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600810 != nil:
    section.add "Version", valid_600810
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
  var valid_600811 = header.getOrDefault("X-Amz-Date")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Date", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Security-Token")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Security-Token", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Content-Sha256", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Algorithm")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Algorithm", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Signature")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Signature", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-SignedHeaders", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Credential")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Credential", valid_600817
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600818 = formData.getOrDefault("DomainName")
  valid_600818 = validateParameter(valid_600818, JString, required = true,
                                 default = nil)
  if valid_600818 != nil:
    section.add "DomainName", valid_600818
  var valid_600819 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_600819
  var valid_600820 = formData.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_600820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600821: Call_PostUpdateDomainEndpointOptions_600806;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600821.validator(path, query, header, formData, body)
  let scheme = call_600821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600821.url(scheme.get, call_600821.host, call_600821.base,
                         call_600821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600821, url, valid)

proc call*(call_600822: Call_PostUpdateDomainEndpointOptions_600806;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: string (required)
  var query_600823 = newJObject()
  var formData_600824 = newJObject()
  add(formData_600824, "DomainName", newJString(DomainName))
  add(formData_600824, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_600823, "Action", newJString(Action))
  add(formData_600824, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_600823, "Version", newJString(Version))
  result = call_600822.call(nil, query_600823, nil, formData_600824, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_600806(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_600807, base: "/",
    url: url_PostUpdateDomainEndpointOptions_600808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_600788 = ref object of OpenApiRestCall_599368
proc url_GetUpdateDomainEndpointOptions_600790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDomainEndpointOptions_600789(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Action: JString (required)
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_600791 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_600791
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600792 = query.getOrDefault("Action")
  valid_600792 = validateParameter(valid_600792, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_600792 != nil:
    section.add "Action", valid_600792
  var valid_600793 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_600793
  var valid_600794 = query.getOrDefault("DomainName")
  valid_600794 = validateParameter(valid_600794, JString, required = true,
                                 default = nil)
  if valid_600794 != nil:
    section.add "DomainName", valid_600794
  var valid_600795 = query.getOrDefault("Version")
  valid_600795 = validateParameter(valid_600795, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600795 != nil:
    section.add "Version", valid_600795
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
  var valid_600796 = header.getOrDefault("X-Amz-Date")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Date", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-Security-Token")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Security-Token", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Content-Sha256", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Algorithm")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Algorithm", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Signature")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Signature", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-SignedHeaders", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Credential")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Credential", valid_600802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600803: Call_GetUpdateDomainEndpointOptions_600788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600803.validator(path, query, header, formData, body)
  let scheme = call_600803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600803.url(scheme.get, call_600803.host, call_600803.base,
                         call_600803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600803, url, valid)

proc call*(call_600804: Call_GetUpdateDomainEndpointOptions_600788;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_600805 = newJObject()
  add(query_600805, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_600805, "Action", newJString(Action))
  add(query_600805, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_600805, "DomainName", newJString(DomainName))
  add(query_600805, "Version", newJString(Version))
  result = call_600804.call(nil, query_600805, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_600788(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_600789, base: "/",
    url: url_GetUpdateDomainEndpointOptions_600790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_600844 = ref object of OpenApiRestCall_599368
proc url_PostUpdateScalingParameters_600846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateScalingParameters_600845(path: JsonNode; query: JsonNode;
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
  var valid_600847 = query.getOrDefault("Action")
  valid_600847 = validateParameter(valid_600847, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_600847 != nil:
    section.add "Action", valid_600847
  var valid_600848 = query.getOrDefault("Version")
  valid_600848 = validateParameter(valid_600848, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600848 != nil:
    section.add "Version", valid_600848
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
  var valid_600849 = header.getOrDefault("X-Amz-Date")
  valid_600849 = validateParameter(valid_600849, JString, required = false,
                                 default = nil)
  if valid_600849 != nil:
    section.add "X-Amz-Date", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Security-Token")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Security-Token", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Content-Sha256", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Algorithm")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Algorithm", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Signature")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Signature", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-SignedHeaders", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Credential")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Credential", valid_600855
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
  var valid_600856 = formData.getOrDefault("DomainName")
  valid_600856 = validateParameter(valid_600856, JString, required = true,
                                 default = nil)
  if valid_600856 != nil:
    section.add "DomainName", valid_600856
  var valid_600857 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_600857
  var valid_600858 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_600858
  var valid_600859 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_600859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600860: Call_PostUpdateScalingParameters_600844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600860.validator(path, query, header, formData, body)
  let scheme = call_600860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600860.url(scheme.get, call_600860.host, call_600860.base,
                         call_600860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600860, url, valid)

proc call*(call_600861: Call_PostUpdateScalingParameters_600844;
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
  var query_600862 = newJObject()
  var formData_600863 = newJObject()
  add(formData_600863, "DomainName", newJString(DomainName))
  add(formData_600863, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_600862, "Action", newJString(Action))
  add(formData_600863, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_600863, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_600862, "Version", newJString(Version))
  result = call_600861.call(nil, query_600862, nil, formData_600863, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_600844(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_600845, base: "/",
    url: url_PostUpdateScalingParameters_600846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_600825 = ref object of OpenApiRestCall_599368
proc url_GetUpdateScalingParameters_600827(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateScalingParameters_600826(path: JsonNode; query: JsonNode;
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
  var valid_600828 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_600828
  var valid_600829 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_600829
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600830 = query.getOrDefault("Action")
  valid_600830 = validateParameter(valid_600830, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_600830 != nil:
    section.add "Action", valid_600830
  var valid_600831 = query.getOrDefault("DomainName")
  valid_600831 = validateParameter(valid_600831, JString, required = true,
                                 default = nil)
  if valid_600831 != nil:
    section.add "DomainName", valid_600831
  var valid_600832 = query.getOrDefault("Version")
  valid_600832 = validateParameter(valid_600832, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600832 != nil:
    section.add "Version", valid_600832
  var valid_600833 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_600833
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
  var valid_600834 = header.getOrDefault("X-Amz-Date")
  valid_600834 = validateParameter(valid_600834, JString, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "X-Amz-Date", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Security-Token")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Security-Token", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Content-Sha256", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Algorithm")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Algorithm", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Signature")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Signature", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-SignedHeaders", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Credential")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Credential", valid_600840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600841: Call_GetUpdateScalingParameters_600825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_600841.validator(path, query, header, formData, body)
  let scheme = call_600841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600841.url(scheme.get, call_600841.host, call_600841.base,
                         call_600841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600841, url, valid)

proc call*(call_600842: Call_GetUpdateScalingParameters_600825; DomainName: string;
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
  var query_600843 = newJObject()
  add(query_600843, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_600843, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_600843, "Action", newJString(Action))
  add(query_600843, "DomainName", newJString(DomainName))
  add(query_600843, "Version", newJString(Version))
  add(query_600843, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_600842.call(nil, query_600843, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_600825(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_600826, base: "/",
    url: url_GetUpdateScalingParameters_600827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_600881 = ref object of OpenApiRestCall_599368
proc url_PostUpdateServiceAccessPolicies_600883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_600882(path: JsonNode;
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
  var valid_600884 = query.getOrDefault("Action")
  valid_600884 = validateParameter(valid_600884, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_600884 != nil:
    section.add "Action", valid_600884
  var valid_600885 = query.getOrDefault("Version")
  valid_600885 = validateParameter(valid_600885, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600885 != nil:
    section.add "Version", valid_600885
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
  var valid_600886 = header.getOrDefault("X-Amz-Date")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Date", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Security-Token")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Security-Token", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
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
  var valid_600893 = formData.getOrDefault("DomainName")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = nil)
  if valid_600893 != nil:
    section.add "DomainName", valid_600893
  var valid_600894 = formData.getOrDefault("AccessPolicies")
  valid_600894 = validateParameter(valid_600894, JString, required = true,
                                 default = nil)
  if valid_600894 != nil:
    section.add "AccessPolicies", valid_600894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600895: Call_PostUpdateServiceAccessPolicies_600881;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_600895.validator(path, query, header, formData, body)
  let scheme = call_600895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600895.url(scheme.get, call_600895.host, call_600895.base,
                         call_600895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600895, url, valid)

proc call*(call_600896: Call_PostUpdateServiceAccessPolicies_600881;
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
  var query_600897 = newJObject()
  var formData_600898 = newJObject()
  add(formData_600898, "DomainName", newJString(DomainName))
  add(formData_600898, "AccessPolicies", newJString(AccessPolicies))
  add(query_600897, "Action", newJString(Action))
  add(query_600897, "Version", newJString(Version))
  result = call_600896.call(nil, query_600897, nil, formData_600898, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_600881(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_600882, base: "/",
    url: url_PostUpdateServiceAccessPolicies_600883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_600864 = ref object of OpenApiRestCall_599368
proc url_GetUpdateServiceAccessPolicies_600866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_600865(path: JsonNode;
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
  var valid_600867 = query.getOrDefault("Action")
  valid_600867 = validateParameter(valid_600867, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_600867 != nil:
    section.add "Action", valid_600867
  var valid_600868 = query.getOrDefault("AccessPolicies")
  valid_600868 = validateParameter(valid_600868, JString, required = true,
                                 default = nil)
  if valid_600868 != nil:
    section.add "AccessPolicies", valid_600868
  var valid_600869 = query.getOrDefault("DomainName")
  valid_600869 = validateParameter(valid_600869, JString, required = true,
                                 default = nil)
  if valid_600869 != nil:
    section.add "DomainName", valid_600869
  var valid_600870 = query.getOrDefault("Version")
  valid_600870 = validateParameter(valid_600870, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_600870 != nil:
    section.add "Version", valid_600870
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
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600878: Call_GetUpdateServiceAccessPolicies_600864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_600878.validator(path, query, header, formData, body)
  let scheme = call_600878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600878.url(scheme.get, call_600878.host, call_600878.base,
                         call_600878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600878, url, valid)

proc call*(call_600879: Call_GetUpdateServiceAccessPolicies_600864;
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
  var query_600880 = newJObject()
  add(query_600880, "Action", newJString(Action))
  add(query_600880, "AccessPolicies", newJString(AccessPolicies))
  add(query_600880, "DomainName", newJString(DomainName))
  add(query_600880, "Version", newJString(Version))
  result = call_600879.call(nil, query_600880, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_600864(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_600865, base: "/",
    url: url_GetUpdateServiceAccessPolicies_600866,
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
