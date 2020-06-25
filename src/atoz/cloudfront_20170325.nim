
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2017-03-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20170325_21626019 = ref object of OpenApiRestCall_21625435
proc url_CreateCloudFrontOriginAccessIdentity20170325_21626021(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20170325_21626020(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_21626022 = header.getOrDefault("X-Amz-Date")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Date", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Security-Token", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Algorithm", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Signature")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Signature", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Credential")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Credential", valid_21626028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626030: Call_CreateCloudFrontOriginAccessIdentity20170325_21626019;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_CreateCloudFrontOriginAccessIdentity20170325_21626019;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20170325
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_21626032 = newJObject()
  if body != nil:
    body_21626032 = body
  result = call_21626031.call(nil, nil, nil, nil, body_21626032)

var createCloudFrontOriginAccessIdentity20170325* = Call_CreateCloudFrontOriginAccessIdentity20170325_21626019(
    name: "createCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20170325_21626020,
    base: "/", makeUrl: url_CreateCloudFrontOriginAccessIdentity20170325_21626021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20170325_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListCloudFrontOriginAccessIdentities20170325_21625781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20170325_21625780(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_21625882 = query.getOrDefault("Marker")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Marker", valid_21625882
  var valid_21625883 = query.getOrDefault("MaxItems")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "MaxItems", valid_21625883
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
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_ListCloudFrontOriginAccessIdentities20170325_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_ListCloudFrontOriginAccessIdentities20170325_21625779;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20170325
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_21625980 = newJObject()
  add(query_21625980, "Marker", newJString(Marker))
  add(query_21625980, "MaxItems", newJString(MaxItems))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20170325* = Call_ListCloudFrontOriginAccessIdentities20170325_21625779(
    name: "listCloudFrontOriginAccessIdentities20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20170325_21625780,
    base: "/", makeUrl: url_ListCloudFrontOriginAccessIdentities20170325_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20170325_21626048 = ref object of OpenApiRestCall_21625435
proc url_CreateDistribution20170325_21626050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20170325_21626049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_21626051 = header.getOrDefault("X-Amz-Date")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Date", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Security-Token", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Algorithm", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Signature")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Signature", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Credential")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Credential", valid_21626057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626059: Call_CreateDistribution20170325_21626048;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_CreateDistribution20170325_21626048; body: JsonNode): Recallable =
  ## createDistribution20170325
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   body: JObject (required)
  var body_21626061 = newJObject()
  if body != nil:
    body_21626061 = body
  result = call_21626060.call(nil, nil, nil, nil, body_21626061)

var createDistribution20170325* = Call_CreateDistribution20170325_21626048(
    name: "createDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_CreateDistribution20170325_21626049, base: "/",
    makeUrl: url_CreateDistribution20170325_21626050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20170325_21626033 = ref object of OpenApiRestCall_21625435
proc url_ListDistributions20170325_21626035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20170325_21626034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_21626036 = query.getOrDefault("Marker")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "Marker", valid_21626036
  var valid_21626037 = query.getOrDefault("MaxItems")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "MaxItems", valid_21626037
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
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_ListDistributions20170325_21626033;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List distributions. 
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_ListDistributions20170325_21626033;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributions20170325
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_21626047 = newJObject()
  add(query_21626047, "Marker", newJString(Marker))
  add(query_21626047, "MaxItems", newJString(MaxItems))
  result = call_21626046.call(nil, query_21626047, nil, nil, nil)

var listDistributions20170325* = Call_ListDistributions20170325_21626033(
    name: "listDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_ListDistributions20170325_21626034, base: "/",
    makeUrl: url_ListDistributions20170325_21626035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20170325_21626062 = ref object of OpenApiRestCall_21625435
proc url_CreateDistributionWithTags20170325_21626064(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20170325_21626063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_21626065 = query.getOrDefault("WithTags")
  valid_21626065 = validateParameter(valid_21626065, JBool, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "WithTags", valid_21626065
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
  var valid_21626066 = header.getOrDefault("X-Amz-Date")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Date", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Security-Token", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Algorithm", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Signature")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Signature", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Credential")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Credential", valid_21626072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626074: Call_CreateDistributionWithTags20170325_21626062;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_CreateDistributionWithTags20170325_21626062;
          WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20170325
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_21626076 = newJObject()
  var body_21626077 = newJObject()
  add(query_21626076, "WithTags", newJBool(WithTags))
  if body != nil:
    body_21626077 = body
  result = call_21626075.call(nil, query_21626076, nil, nil, body_21626077)

var createDistributionWithTags20170325* = Call_CreateDistributionWithTags20170325_21626062(
    name: "createDistributionWithTags20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20170325_21626063, base: "/",
    makeUrl: url_CreateDistributionWithTags20170325_21626064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20170325_21626108 = ref object of OpenApiRestCall_21625435
proc url_CreateInvalidation20170325_21626110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20170325_21626109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_21626111 = path.getOrDefault("DistributionId")
  valid_21626111 = validateParameter(valid_21626111, JString, required = true,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "DistributionId", valid_21626111
  result.add "path", section
  section = newJObject()
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
  var valid_21626112 = header.getOrDefault("X-Amz-Date")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Date", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Security-Token", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Algorithm", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Signature")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Signature", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Credential")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Credential", valid_21626118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626120: Call_CreateInvalidation20170325_21626108;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_21626120.validator(path, query, header, formData, body, _)
  let scheme = call_21626120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626120.makeUrl(scheme.get, call_21626120.host, call_21626120.base,
                               call_21626120.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626120, uri, valid, _)

proc call*(call_21626121: Call_CreateInvalidation20170325_21626108; body: JsonNode;
          DistributionId: string): Recallable =
  ## createInvalidation20170325
  ## Create a new invalidation. 
  ##   body: JObject (required)
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  var path_21626122 = newJObject()
  var body_21626123 = newJObject()
  if body != nil:
    body_21626123 = body
  add(path_21626122, "DistributionId", newJString(DistributionId))
  result = call_21626121.call(path_21626122, nil, nil, nil, body_21626123)

var createInvalidation20170325* = Call_CreateInvalidation20170325_21626108(
    name: "createInvalidation20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20170325_21626109, base: "/",
    makeUrl: url_CreateInvalidation20170325_21626110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20170325_21626078 = ref object of OpenApiRestCall_21625435
proc url_ListInvalidations20170325_21626080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20170325_21626079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_21626094 = path.getOrDefault("DistributionId")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "DistributionId", valid_21626094
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_21626095 = query.getOrDefault("Marker")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "Marker", valid_21626095
  var valid_21626096 = query.getOrDefault("MaxItems")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "MaxItems", valid_21626096
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
  var valid_21626097 = header.getOrDefault("X-Amz-Date")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Date", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Security-Token", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Algorithm", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Signature")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Signature", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Credential")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Credential", valid_21626103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626104: Call_ListInvalidations20170325_21626078;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_21626104.validator(path, query, header, formData, body, _)
  let scheme = call_21626104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626104.makeUrl(scheme.get, call_21626104.host, call_21626104.base,
                               call_21626104.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626104, uri, valid, _)

proc call*(call_21626105: Call_ListInvalidations20170325_21626078;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20170325
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_21626106 = newJObject()
  var query_21626107 = newJObject()
  add(query_21626107, "Marker", newJString(Marker))
  add(query_21626107, "MaxItems", newJString(MaxItems))
  add(path_21626106, "DistributionId", newJString(DistributionId))
  result = call_21626105.call(path_21626106, query_21626107, nil, nil, nil)

var listInvalidations20170325* = Call_ListInvalidations20170325_21626078(
    name: "listInvalidations20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20170325_21626079, base: "/",
    makeUrl: url_ListInvalidations20170325_21626080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20170325_21626139 = ref object of OpenApiRestCall_21625435
proc url_CreateStreamingDistribution20170325_21626141(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20170325_21626140(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_21626142 = header.getOrDefault("X-Amz-Date")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Date", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Security-Token", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Algorithm", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Signature")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Signature", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Credential")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Credential", valid_21626148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626150: Call_CreateStreamingDistribution20170325_21626139;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_21626150.validator(path, query, header, formData, body, _)
  let scheme = call_21626150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626150.makeUrl(scheme.get, call_21626150.host, call_21626150.base,
                               call_21626150.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626150, uri, valid, _)

proc call*(call_21626151: Call_CreateStreamingDistribution20170325_21626139;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20170325
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_21626152 = newJObject()
  if body != nil:
    body_21626152 = body
  result = call_21626151.call(nil, nil, nil, nil, body_21626152)

var createStreamingDistribution20170325* = Call_CreateStreamingDistribution20170325_21626139(
    name: "createStreamingDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20170325_21626140, base: "/",
    makeUrl: url_CreateStreamingDistribution20170325_21626141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20170325_21626124 = ref object of OpenApiRestCall_21625435
proc url_ListStreamingDistributions20170325_21626126(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20170325_21626125(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_21626127 = query.getOrDefault("Marker")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "Marker", valid_21626127
  var valid_21626128 = query.getOrDefault("MaxItems")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "MaxItems", valid_21626128
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
  var valid_21626129 = header.getOrDefault("X-Amz-Date")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Date", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Security-Token", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Algorithm", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Signature")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Signature", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Credential")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Credential", valid_21626135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626136: Call_ListStreamingDistributions20170325_21626124;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_21626136.validator(path, query, header, formData, body, _)
  let scheme = call_21626136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626136.makeUrl(scheme.get, call_21626136.host, call_21626136.base,
                               call_21626136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626136, uri, valid, _)

proc call*(call_21626137: Call_ListStreamingDistributions20170325_21626124;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20170325
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_21626138 = newJObject()
  add(query_21626138, "Marker", newJString(Marker))
  add(query_21626138, "MaxItems", newJString(MaxItems))
  result = call_21626137.call(nil, query_21626138, nil, nil, nil)

var listStreamingDistributions20170325* = Call_ListStreamingDistributions20170325_21626124(
    name: "listStreamingDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20170325_21626125, base: "/",
    makeUrl: url_ListStreamingDistributions20170325_21626126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20170325_21626153 = ref object of OpenApiRestCall_21625435
proc url_CreateStreamingDistributionWithTags20170325_21626155(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20170325_21626154(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_21626156 = query.getOrDefault("WithTags")
  valid_21626156 = validateParameter(valid_21626156, JBool, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "WithTags", valid_21626156
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
  var valid_21626157 = header.getOrDefault("X-Amz-Date")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Date", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Security-Token", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Algorithm", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Signature")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Signature", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Credential")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Credential", valid_21626163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626165: Call_CreateStreamingDistributionWithTags20170325_21626153;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_21626165.validator(path, query, header, formData, body, _)
  let scheme = call_21626165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626165.makeUrl(scheme.get, call_21626165.host, call_21626165.base,
                               call_21626165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626165, uri, valid, _)

proc call*(call_21626166: Call_CreateStreamingDistributionWithTags20170325_21626153;
          WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20170325
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_21626167 = newJObject()
  var body_21626168 = newJObject()
  add(query_21626167, "WithTags", newJBool(WithTags))
  if body != nil:
    body_21626168 = body
  result = call_21626166.call(nil, query_21626167, nil, nil, body_21626168)

var createStreamingDistributionWithTags20170325* = Call_CreateStreamingDistributionWithTags20170325_21626153(
    name: "createStreamingDistributionWithTags20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20170325_21626154,
    base: "/", makeUrl: url_CreateStreamingDistributionWithTags20170325_21626155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20170325_21626169 = ref object of OpenApiRestCall_21625435
proc url_GetCloudFrontOriginAccessIdentity20170325_21626171(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20170325_21626170(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626172 = path.getOrDefault("Id")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "Id", valid_21626172
  result.add "path", section
  section = newJObject()
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
  var valid_21626173 = header.getOrDefault("X-Amz-Date")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Date", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Security-Token", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Algorithm", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Signature")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Signature", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Credential")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Credential", valid_21626179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626180: Call_GetCloudFrontOriginAccessIdentity20170325_21626169;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_21626180.validator(path, query, header, formData, body, _)
  let scheme = call_21626180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626180.makeUrl(scheme.get, call_21626180.host, call_21626180.base,
                               call_21626180.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626180, uri, valid, _)

proc call*(call_21626181: Call_GetCloudFrontOriginAccessIdentity20170325_21626169;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20170325
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_21626182 = newJObject()
  add(path_21626182, "Id", newJString(Id))
  result = call_21626181.call(path_21626182, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20170325* = Call_GetCloudFrontOriginAccessIdentity20170325_21626169(
    name: "getCloudFrontOriginAccessIdentity20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20170325_21626170,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentity20170325_21626171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20170325_21626183 = ref object of OpenApiRestCall_21625435
proc url_DeleteCloudFrontOriginAccessIdentity20170325_21626185(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20170325_21626184(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626186 = path.getOrDefault("Id")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "Id", valid_21626186
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626187 = header.getOrDefault("X-Amz-Date")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Date", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Security-Token", valid_21626188
  var valid_21626189 = header.getOrDefault("If-Match")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "If-Match", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Algorithm", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Signature")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Signature", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Credential")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Credential", valid_21626194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626195: Call_DeleteCloudFrontOriginAccessIdentity20170325_21626183;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_21626195.validator(path, query, header, formData, body, _)
  let scheme = call_21626195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626195.makeUrl(scheme.get, call_21626195.host, call_21626195.base,
                               call_21626195.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626195, uri, valid, _)

proc call*(call_21626196: Call_DeleteCloudFrontOriginAccessIdentity20170325_21626183;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20170325
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_21626197 = newJObject()
  add(path_21626197, "Id", newJString(Id))
  result = call_21626196.call(path_21626197, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20170325* = Call_DeleteCloudFrontOriginAccessIdentity20170325_21626183(
    name: "deleteCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20170325_21626184,
    base: "/", makeUrl: url_DeleteCloudFrontOriginAccessIdentity20170325_21626185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20170325_21626198 = ref object of OpenApiRestCall_21625435
proc url_GetDistribution20170325_21626200(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20170325_21626199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626201 = path.getOrDefault("Id")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "Id", valid_21626201
  result.add "path", section
  section = newJObject()
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
  var valid_21626202 = header.getOrDefault("X-Amz-Date")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Date", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Security-Token", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Algorithm", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Signature")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Signature", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Credential")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Credential", valid_21626208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626209: Call_GetDistribution20170325_21626198;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_21626209.validator(path, query, header, formData, body, _)
  let scheme = call_21626209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626209.makeUrl(scheme.get, call_21626209.host, call_21626209.base,
                               call_21626209.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626209, uri, valid, _)

proc call*(call_21626210: Call_GetDistribution20170325_21626198; Id: string): Recallable =
  ## getDistribution20170325
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_21626211 = newJObject()
  add(path_21626211, "Id", newJString(Id))
  result = call_21626210.call(path_21626211, nil, nil, nil, nil)

var getDistribution20170325* = Call_GetDistribution20170325_21626198(
    name: "getDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_GetDistribution20170325_21626199, base: "/",
    makeUrl: url_GetDistribution20170325_21626200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20170325_21626212 = ref object of OpenApiRestCall_21625435
proc url_DeleteDistribution20170325_21626214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20170325_21626213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626215 = path.getOrDefault("Id")
  valid_21626215 = validateParameter(valid_21626215, JString, required = true,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "Id", valid_21626215
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626216 = header.getOrDefault("X-Amz-Date")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Date", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Security-Token", valid_21626217
  var valid_21626218 = header.getOrDefault("If-Match")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "If-Match", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Algorithm", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Signature")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Signature", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Credential")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Credential", valid_21626223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626224: Call_DeleteDistribution20170325_21626212;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_21626224.validator(path, query, header, formData, body, _)
  let scheme = call_21626224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626224.makeUrl(scheme.get, call_21626224.host, call_21626224.base,
                               call_21626224.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626224, uri, valid, _)

proc call*(call_21626225: Call_DeleteDistribution20170325_21626212; Id: string): Recallable =
  ## deleteDistribution20170325
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_21626226 = newJObject()
  add(path_21626226, "Id", newJString(Id))
  result = call_21626225.call(path_21626226, nil, nil, nil, nil)

var deleteDistribution20170325* = Call_DeleteDistribution20170325_21626212(
    name: "deleteDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_DeleteDistribution20170325_21626213, base: "/",
    makeUrl: url_DeleteDistribution20170325_21626214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceLinkedRole20170325_21626227 = ref object of OpenApiRestCall_21625435
proc url_DeleteServiceLinkedRole20170325_21626229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "RoleName" in path, "`RoleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/service-linked-role/"),
               (kind: VariableSegment, value: "RoleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteServiceLinkedRole20170325_21626228(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RoleName: JString (required)
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `RoleName` field"
  var valid_21626230 = path.getOrDefault("RoleName")
  valid_21626230 = validateParameter(valid_21626230, JString, required = true,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "RoleName", valid_21626230
  result.add "path", section
  section = newJObject()
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
  var valid_21626231 = header.getOrDefault("X-Amz-Date")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Date", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Security-Token", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Algorithm", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Signature")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Signature", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Credential")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Credential", valid_21626237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626238: Call_DeleteServiceLinkedRole20170325_21626227;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626238.validator(path, query, header, formData, body, _)
  let scheme = call_21626238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626238.makeUrl(scheme.get, call_21626238.host, call_21626238.base,
                               call_21626238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626238, uri, valid, _)

proc call*(call_21626239: Call_DeleteServiceLinkedRole20170325_21626227;
          RoleName: string): Recallable =
  ## deleteServiceLinkedRole20170325
  ##   RoleName: string (required)
  var path_21626240 = newJObject()
  add(path_21626240, "RoleName", newJString(RoleName))
  result = call_21626239.call(path_21626240, nil, nil, nil, nil)

var deleteServiceLinkedRole20170325* = Call_DeleteServiceLinkedRole20170325_21626227(
    name: "deleteServiceLinkedRole20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/service-linked-role/{RoleName}",
    validator: validate_DeleteServiceLinkedRole20170325_21626228, base: "/",
    makeUrl: url_DeleteServiceLinkedRole20170325_21626229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20170325_21626241 = ref object of OpenApiRestCall_21625435
proc url_GetStreamingDistribution20170325_21626243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20170325_21626242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626244 = path.getOrDefault("Id")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "Id", valid_21626244
  result.add "path", section
  section = newJObject()
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626252: Call_GetStreamingDistribution20170325_21626241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_GetStreamingDistribution20170325_21626241;
          Id: string): Recallable =
  ## getStreamingDistribution20170325
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_21626254 = newJObject()
  add(path_21626254, "Id", newJString(Id))
  result = call_21626253.call(path_21626254, nil, nil, nil, nil)

var getStreamingDistribution20170325* = Call_GetStreamingDistribution20170325_21626241(
    name: "getStreamingDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20170325_21626242, base: "/",
    makeUrl: url_GetStreamingDistribution20170325_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20170325_21626255 = ref object of OpenApiRestCall_21625435
proc url_DeleteStreamingDistribution20170325_21626257(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20170325_21626256(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626258 = path.getOrDefault("Id")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "Id", valid_21626258
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("If-Match")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "If-Match", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Algorithm", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Signature")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Signature", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Credential")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Credential", valid_21626266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626267: Call_DeleteStreamingDistribution20170325_21626255;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_DeleteStreamingDistribution20170325_21626255;
          Id: string): Recallable =
  ## deleteStreamingDistribution20170325
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_21626269 = newJObject()
  add(path_21626269, "Id", newJString(Id))
  result = call_21626268.call(path_21626269, nil, nil, nil, nil)

var deleteStreamingDistribution20170325* = Call_DeleteStreamingDistribution20170325_21626255(
    name: "deleteStreamingDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20170325_21626256, base: "/",
    makeUrl: url_DeleteStreamingDistribution20170325_21626257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20170325_21626284 = ref object of OpenApiRestCall_21625435
proc url_UpdateCloudFrontOriginAccessIdentity20170325_21626286(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20170325_21626285(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626287 = path.getOrDefault("Id")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "Id", valid_21626287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626288 = header.getOrDefault("X-Amz-Date")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Date", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Security-Token", valid_21626289
  var valid_21626290 = header.getOrDefault("If-Match")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "If-Match", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Algorithm", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Signature")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Signature", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Credential")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Credential", valid_21626295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626297: Call_UpdateCloudFrontOriginAccessIdentity20170325_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_21626297.validator(path, query, header, formData, body, _)
  let scheme = call_21626297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626297.makeUrl(scheme.get, call_21626297.host, call_21626297.base,
                               call_21626297.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626297, uri, valid, _)

proc call*(call_21626298: Call_UpdateCloudFrontOriginAccessIdentity20170325_21626284;
          Id: string; body: JsonNode): Recallable =
  ## updateCloudFrontOriginAccessIdentity20170325
  ## Update an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's id.
  ##   body: JObject (required)
  var path_21626299 = newJObject()
  var body_21626300 = newJObject()
  add(path_21626299, "Id", newJString(Id))
  if body != nil:
    body_21626300 = body
  result = call_21626298.call(path_21626299, nil, nil, nil, body_21626300)

var updateCloudFrontOriginAccessIdentity20170325* = Call_UpdateCloudFrontOriginAccessIdentity20170325_21626284(
    name: "updateCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20170325_21626285,
    base: "/", makeUrl: url_UpdateCloudFrontOriginAccessIdentity20170325_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20170325_21626270 = ref object of OpenApiRestCall_21625435
proc url_GetCloudFrontOriginAccessIdentityConfig20170325_21626272(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20170325_21626271(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626273 = path.getOrDefault("Id")
  valid_21626273 = validateParameter(valid_21626273, JString, required = true,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "Id", valid_21626273
  result.add "path", section
  section = newJObject()
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
  var valid_21626274 = header.getOrDefault("X-Amz-Date")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Date", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Security-Token", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Algorithm", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Signature")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Signature", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Credential")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Credential", valid_21626280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_GetCloudFrontOriginAccessIdentityConfig20170325_21626270;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_GetCloudFrontOriginAccessIdentityConfig20170325_21626270;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20170325
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_21626283 = newJObject()
  add(path_21626283, "Id", newJString(Id))
  result = call_21626282.call(path_21626283, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20170325* = Call_GetCloudFrontOriginAccessIdentityConfig20170325_21626270(
    name: "getCloudFrontOriginAccessIdentityConfig20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20170325_21626271,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentityConfig20170325_21626272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20170325_21626315 = ref object of OpenApiRestCall_21625435
proc url_UpdateDistribution20170325_21626317(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20170325_21626316(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626318 = path.getOrDefault("Id")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "Id", valid_21626318
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626319 = header.getOrDefault("X-Amz-Date")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Date", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Security-Token", valid_21626320
  var valid_21626321 = header.getOrDefault("If-Match")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "If-Match", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626328: Call_UpdateDistribution20170325_21626315;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_UpdateDistribution20170325_21626315; Id: string;
          body: JsonNode): Recallable =
  ## updateDistribution20170325
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ##   Id: string (required)
  ##     : The distribution's id.
  ##   body: JObject (required)
  var path_21626330 = newJObject()
  var body_21626331 = newJObject()
  add(path_21626330, "Id", newJString(Id))
  if body != nil:
    body_21626331 = body
  result = call_21626329.call(path_21626330, nil, nil, nil, body_21626331)

var updateDistribution20170325* = Call_UpdateDistribution20170325_21626315(
    name: "updateDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20170325_21626316, base: "/",
    makeUrl: url_UpdateDistribution20170325_21626317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20170325_21626301 = ref object of OpenApiRestCall_21625435
proc url_GetDistributionConfig20170325_21626303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20170325_21626302(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626304 = path.getOrDefault("Id")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "Id", valid_21626304
  result.add "path", section
  section = newJObject()
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
  var valid_21626305 = header.getOrDefault("X-Amz-Date")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Date", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Security-Token", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Algorithm", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Signature")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Signature", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Credential")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Credential", valid_21626311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626312: Call_GetDistributionConfig20170325_21626301;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_21626312.validator(path, query, header, formData, body, _)
  let scheme = call_21626312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626312.makeUrl(scheme.get, call_21626312.host, call_21626312.base,
                               call_21626312.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626312, uri, valid, _)

proc call*(call_21626313: Call_GetDistributionConfig20170325_21626301; Id: string): Recallable =
  ## getDistributionConfig20170325
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_21626314 = newJObject()
  add(path_21626314, "Id", newJString(Id))
  result = call_21626313.call(path_21626314, nil, nil, nil, nil)

var getDistributionConfig20170325* = Call_GetDistributionConfig20170325_21626301(
    name: "getDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20170325_21626302, base: "/",
    makeUrl: url_GetDistributionConfig20170325_21626303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20170325_21626332 = ref object of OpenApiRestCall_21625435
proc url_GetInvalidation20170325_21626334(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20170325_21626333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626335 = path.getOrDefault("Id")
  valid_21626335 = validateParameter(valid_21626335, JString, required = true,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "Id", valid_21626335
  var valid_21626336 = path.getOrDefault("DistributionId")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "DistributionId", valid_21626336
  result.add "path", section
  section = newJObject()
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
  var valid_21626337 = header.getOrDefault("X-Amz-Date")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Date", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Security-Token", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Algorithm", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Signature")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Signature", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Credential")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Credential", valid_21626343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626344: Call_GetInvalidation20170325_21626332;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_21626344.validator(path, query, header, formData, body, _)
  let scheme = call_21626344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626344.makeUrl(scheme.get, call_21626344.host, call_21626344.base,
                               call_21626344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626344, uri, valid, _)

proc call*(call_21626345: Call_GetInvalidation20170325_21626332; Id: string;
          DistributionId: string): Recallable =
  ## getInvalidation20170325
  ## Get the information about an invalidation. 
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_21626346 = newJObject()
  add(path_21626346, "Id", newJString(Id))
  add(path_21626346, "DistributionId", newJString(DistributionId))
  result = call_21626345.call(path_21626346, nil, nil, nil, nil)

var getInvalidation20170325* = Call_GetInvalidation20170325_21626332(
    name: "getInvalidation20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20170325_21626333, base: "/",
    makeUrl: url_GetInvalidation20170325_21626334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20170325_21626361 = ref object of OpenApiRestCall_21625435
proc url_UpdateStreamingDistribution20170325_21626363(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20170325_21626362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626364 = path.getOrDefault("Id")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "Id", valid_21626364
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626365 = header.getOrDefault("X-Amz-Date")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Date", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Security-Token", valid_21626366
  var valid_21626367 = header.getOrDefault("If-Match")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "If-Match", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Algorithm", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Signature")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Signature", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Credential")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Credential", valid_21626372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626374: Call_UpdateStreamingDistribution20170325_21626361;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_21626374.validator(path, query, header, formData, body, _)
  let scheme = call_21626374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626374.makeUrl(scheme.get, call_21626374.host, call_21626374.base,
                               call_21626374.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626374, uri, valid, _)

proc call*(call_21626375: Call_UpdateStreamingDistribution20170325_21626361;
          Id: string; body: JsonNode): Recallable =
  ## updateStreamingDistribution20170325
  ## Update a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  ##   body: JObject (required)
  var path_21626376 = newJObject()
  var body_21626377 = newJObject()
  add(path_21626376, "Id", newJString(Id))
  if body != nil:
    body_21626377 = body
  result = call_21626375.call(path_21626376, nil, nil, nil, body_21626377)

var updateStreamingDistribution20170325* = Call_UpdateStreamingDistribution20170325_21626361(
    name: "updateStreamingDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20170325_21626362, base: "/",
    makeUrl: url_UpdateStreamingDistribution20170325_21626363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20170325_21626347 = ref object of OpenApiRestCall_21625435
proc url_GetStreamingDistributionConfig20170325_21626349(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20170325_21626348(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626350 = path.getOrDefault("Id")
  valid_21626350 = validateParameter(valid_21626350, JString, required = true,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "Id", valid_21626350
  result.add "path", section
  section = newJObject()
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
  var valid_21626351 = header.getOrDefault("X-Amz-Date")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Date", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Security-Token", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Algorithm", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Signature")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Signature", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Credential")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Credential", valid_21626357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626358: Call_GetStreamingDistributionConfig20170325_21626347;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_21626358.validator(path, query, header, formData, body, _)
  let scheme = call_21626358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626358.makeUrl(scheme.get, call_21626358.host, call_21626358.base,
                               call_21626358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626358, uri, valid, _)

proc call*(call_21626359: Call_GetStreamingDistributionConfig20170325_21626347;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20170325
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_21626360 = newJObject()
  add(path_21626360, "Id", newJString(Id))
  result = call_21626359.call(path_21626360, nil, nil, nil, nil)

var getStreamingDistributionConfig20170325* = Call_GetStreamingDistributionConfig20170325_21626347(
    name: "getStreamingDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20170325_21626348,
    base: "/", makeUrl: url_GetStreamingDistributionConfig20170325_21626349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20170325_21626378 = ref object of OpenApiRestCall_21625435
proc url_ListDistributionsByWebACLId20170325_21626380(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20170325_21626379(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_21626381 = path.getOrDefault("WebACLId")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "WebACLId", valid_21626381
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_21626382 = query.getOrDefault("Marker")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "Marker", valid_21626382
  var valid_21626383 = query.getOrDefault("MaxItems")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "MaxItems", valid_21626383
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
  var valid_21626384 = header.getOrDefault("X-Amz-Date")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Date", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Security-Token", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Algorithm", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Signature")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Signature", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Credential")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Credential", valid_21626390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626391: Call_ListDistributionsByWebACLId20170325_21626378;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_21626391.validator(path, query, header, formData, body, _)
  let scheme = call_21626391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626391.makeUrl(scheme.get, call_21626391.host, call_21626391.base,
                               call_21626391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626391, uri, valid, _)

proc call*(call_21626392: Call_ListDistributionsByWebACLId20170325_21626378;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20170325
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_21626393 = newJObject()
  var query_21626394 = newJObject()
  add(query_21626394, "Marker", newJString(Marker))
  add(query_21626394, "MaxItems", newJString(MaxItems))
  add(path_21626393, "WebACLId", newJString(WebACLId))
  result = call_21626392.call(path_21626393, query_21626394, nil, nil, nil)

var listDistributionsByWebACLId20170325* = Call_ListDistributionsByWebACLId20170325_21626378(
    name: "listDistributionsByWebACLId20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20170325_21626379, base: "/",
    makeUrl: url_ListDistributionsByWebACLId20170325_21626380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20170325_21626395 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource20170325_21626397(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20170325_21626396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_21626398 = query.getOrDefault("Resource")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "Resource", valid_21626398
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
  var valid_21626399 = header.getOrDefault("X-Amz-Date")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Date", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Security-Token", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Algorithm", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Signature")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Signature", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Credential")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Credential", valid_21626405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626406: Call_ListTagsForResource20170325_21626395;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_21626406.validator(path, query, header, formData, body, _)
  let scheme = call_21626406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626406.makeUrl(scheme.get, call_21626406.host, call_21626406.base,
                               call_21626406.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626406, uri, valid, _)

proc call*(call_21626407: Call_ListTagsForResource20170325_21626395;
          Resource: string): Recallable =
  ## listTagsForResource20170325
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_21626408 = newJObject()
  add(query_21626408, "Resource", newJString(Resource))
  result = call_21626407.call(nil, query_21626408, nil, nil, nil)

var listTagsForResource20170325* = Call_ListTagsForResource20170325_21626395(
    name: "listTagsForResource20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/tagging#Resource",
    validator: validate_ListTagsForResource20170325_21626396, base: "/",
    makeUrl: url_ListTagsForResource20170325_21626397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20170325_21626409 = ref object of OpenApiRestCall_21625435
proc url_TagResource20170325_21626411(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20170325_21626410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_21626412 = query.getOrDefault("Resource")
  valid_21626412 = validateParameter(valid_21626412, JString, required = true,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "Resource", valid_21626412
  var valid_21626427 = query.getOrDefault("Operation")
  valid_21626427 = validateParameter(valid_21626427, JString, required = true,
                                   default = newJString("Tag"))
  if valid_21626427 != nil:
    section.add "Operation", valid_21626427
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
  var valid_21626428 = header.getOrDefault("X-Amz-Date")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Date", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Security-Token", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Algorithm", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Signature")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Signature", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Credential")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Credential", valid_21626434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626436: Call_TagResource20170325_21626409; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_21626436.validator(path, query, header, formData, body, _)
  let scheme = call_21626436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626436.makeUrl(scheme.get, call_21626436.host, call_21626436.base,
                               call_21626436.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626436, uri, valid, _)

proc call*(call_21626437: Call_TagResource20170325_21626409; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20170325
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_21626438 = newJObject()
  var body_21626439 = newJObject()
  add(query_21626438, "Resource", newJString(Resource))
  add(query_21626438, "Operation", newJString(Operation))
  if body != nil:
    body_21626439 = body
  result = call_21626437.call(nil, query_21626438, nil, nil, body_21626439)

var tagResource20170325* = Call_TagResource20170325_21626409(
    name: "tagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20170325_21626410, base: "/",
    makeUrl: url_TagResource20170325_21626411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20170325_21626441 = ref object of OpenApiRestCall_21625435
proc url_UntagResource20170325_21626443(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20170325_21626442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_21626444 = query.getOrDefault("Resource")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "Resource", valid_21626444
  var valid_21626445 = query.getOrDefault("Operation")
  valid_21626445 = validateParameter(valid_21626445, JString, required = true,
                                   default = newJString("Untag"))
  if valid_21626445 != nil:
    section.add "Operation", valid_21626445
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
  var valid_21626446 = header.getOrDefault("X-Amz-Date")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Date", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Security-Token", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Algorithm", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Signature")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Signature", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Credential")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Credential", valid_21626452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626454: Call_UntagResource20170325_21626441;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_21626454.validator(path, query, header, formData, body, _)
  let scheme = call_21626454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626454.makeUrl(scheme.get, call_21626454.host, call_21626454.base,
                               call_21626454.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626454, uri, valid, _)

proc call*(call_21626455: Call_UntagResource20170325_21626441; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20170325
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_21626456 = newJObject()
  var body_21626457 = newJObject()
  add(query_21626456, "Resource", newJString(Resource))
  add(query_21626456, "Operation", newJString(Operation))
  if body != nil:
    body_21626457 = body
  result = call_21626455.call(nil, query_21626456, nil, nil, body_21626457)

var untagResource20170325* = Call_UntagResource20170325_21626441(
    name: "untagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20170325_21626442, base: "/",
    makeUrl: url_UntagResource20170325_21626443,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}